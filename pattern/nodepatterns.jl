load("pattern/req.jl")
req("pattern/utils.jl")
req("pretty/pretty.jl")


egal(x,y) = is(x,y)
egal(x::Tuple, y::Tuple) = (length(x) == length(y)) && all(map(egal, x,y))


abstract MaybePattern
type       NoneMatch   <: MaybePattern;  end
abstract   Pattern     <: MaybePattern
abstract     TreePattern <: Pattern
type           Anything    <: TreePattern;  end
abstract     PNode       <: Pattern
abstract       BareNode    <: PNode

const nonematch = NoneMatch()
const anything  = Anything()

show(io::IO, ::NoneMatch) = print(io, "nonematch")
show(io::IO, ::Anything)  = print(io, "anything")

show_sig(io::IO, p::Union(NoneMatch,Anything)) = print(io, "pat(", p, ")")


show_sig(io::IO, x) = show(io, x)
show_sig(x) = show_sig(OUTPUT_STREAM, x)
print_sig(io::IO, args...) = foreach(arg->print_sig(io, arg), args)
print_sig(io::IO, x::Union(Char, String)) = print(io, x)
print_sig(io::IO, x) = show_sig(io, x)
print_sig(args...) = print_sig(OUTPUT_STREAM, args...)

psig(args...) = PNest(print_sig, args...)


type TreeNode <: PNode
    simple_name::BareNode
    tree::TreePattern
end

treenode(::NoneMatch, ::TreePattern) = nonematch
treenode(simple_name::BareNode, tree::TreePattern) = TreeNode(simple_name,tree)

show_sig(io::IO, p::TreeNode) = print_sig(io, p.simple_name, "~", p.tree)


type Atom{T} <: BareNode
    value::T
end
egal{T}(x::Atom{T},y::Atom{T}) = egal(x.value,y.value)

show(io::IO, p::Atom) = pprint(io, enclose("Atom(", PNest(show, p.value), ")"))
show_sig(io::IO, p::Atom) = print(io, p.value)

type PVar <: BareNode
    name::Symbol
    istemp::Bool
end
PVar(name::Symbol) = PVar(name, false)

function show(io::IO, p::PVar) 
    print(io, p.istemp ? "PVar(:$(p.name),true)" : "PVar(:$(p.name))")
end
show_sig(io::IO, p::PVar) = print(io, p.name)


get_simple_name(p::TreeNode) = p.simple_name
get_simple_name(p::BareNode) = p
get_tree(p::TreeNode) = p.tree
get_tree(p::BareNode) = anything


function egal(p::TreeNode, x::TreeNode) 
    egal(p.simple_name, x.simple_name) && egal(p.tree, x.tree)
end


## DelayedTree ##

type DelayedTree <: TreePattern
    p::TreePattern
    x::TreePattern
    result::Union(TreePattern,NoneMatch, Nothing)
    
    DelayedTree(p::TreePattern, x::TreePattern) = new(p, x, nothing)
end

undelayed(p::DelayedTree) = p.result::Union(TreePattern,NoneMatch)
undelayed(p::TreePattern) = p

function undelay(p::TreeNode)
    if isa(p.tree, DelayedTree) && !is(p.tree.result, nothing)
        p.tree = p.tree.result
    end
    p
end
undelay(p::BareNode) = p

undelayed(p::BareNode) = p
function undelayed(p::TreeNode) 
    isa(p.tree, DelayedTree) ? treenode(p.simple_name, p.tree.result) : p
end



map_nodes(f::Function, p::PNode) = f(p)
map_nodes(f::Function, p::DelayedTree) = map_nodes(f, p.result)


as_pnode(p::TreePattern) = treenode(PVar(gensym(),true), p)
as_pnode(p::MaybePattern) = p


# -- Subs ---------------------------------------------------------------------

typealias SubsDict Dict{PNode,PNode}
type Subs
    dict::SubsDict
    disproved_p_ge_x::Bool
    delay_queue::Vector{DelayedTree}

    Subs() = new(SubsDict(),false,[])
end
not_pgex!(s::Subs) = (s.disproved_p_ge_x = true; s)

function lookup(s::Subs, p::PNode)
    if !has(s.dict, p);  undelay(p)
    else;                s.dict[p] = lookup(s, s.dict[p])        
    end
end

function assign(s::Subs, x::PNode, p::PNode)
    @expect !has(s.dict, p)
    if egal(x,p)
        del(s.dict, p)
    else
        s.dict[p] = x
    end
end

function delayed_unify(s::Subs, p::TreePattern,x::TreePattern)
    d = DelayedTree(p,x)
    enqueue(s.delay_queue, d)
    d
end


function show_sig(io::IO, s::Subs)
    print(io, "Subs(", (s.disproved_p_ge_x ? "  " : ">="), ", {")
    let io=indented(io)
        for (k,v) in s.dict
            print(io, "\n", psig(k), " => ", psig(undelay(v)), ", ")
        end
    end
    if !isempty(s.dict);  print(io, "\n");  end
    print(io, "}", s.delay_queue, ")")
end


# -- unite --------------------------------------------------------------------

unite(         p::PNode, x::PNode) = unite_ps(   p,x)[1]
unite(s::Subs, p::PNode, x::PNode) = unite_ps(s, p,x)[1]

unite_ps(p::PNode, x::PNode) = unite_ps(Subs(), p,x)
function unite_ps(s::Subs, p::PNode, x::PNode)
    y = unite_step(s, p,x)
    while !isempty(s.delay_queue)
        d = pop(s.delay_queue)
        p, x = undelayed(d.p), undelayed(d.x)

        # unify the tree patterns
        local y = unify(s, p,x)
        if is(y,nonematch);  return (nonematch, s);  end

        d.result = y
    end
    y = normalized_pattern(s,y)
    y, s
end

self_unite(s::Subs, p::BareNode) = p
function self_unite(s::Subs, p::TreeNode)
    pname = p.simple_name
    x = lookup(s, pname)
    if egal(lookup(s,p), x);  return x;  end
    
    if egal(x,pname)
        s[x] = p
    else
        # p is unbound in s, as is x
        raw_unite_step(s, p,x)    
    end
end


function unite_step(s::Subs, p::PNode, x::PNode)
    p, x = self_unite(s,p), self_unite(s,x)
    p, x = lookup(s,p), lookup(s,x)

    raw_unite_step(s, p,x)
end

# assumes p and x are unbound in s
function raw_unite_step(s::Subs, p::PNode, x::PNode)
    @assert !has(s.dict, p)
    @assert !has(s.dict, x)

    if egal(p,x);  return x;  end
    
    y = unify(s, p,x)
    if is(y,nonematch);  return nonematch;  end
    s[p] = s[x] = y
    get_simple_name(y)
end


#normalized_pattern(s::Subs, ps::Tuple) = map(p->(normalized_pattern(s,p)), ps)

normalized_pattern(s::Subs, ::NoneMatch) = nonematch
normalized_pattern(s::Subs, p::PNode) = normalized_pattern(s,Set{BareNode}(),p)
function normalized_pattern(s::Subs,nodes::Set{BareNode}, p::PNode)
    p=lookup(s,p)
    if isa(p,BareNode)
        return p
    elseif isa(p,TreeNode)
        if has(nodes, p.simple_name)
            return p.simple_name
        else
            add(nodes, p.simple_name)
            return treenode(p.simple_name, 
                            map_nodes(p->normalized_pattern(s,nodes,p),p.tree))
        end
    else
        error("unexpected!")
    end
end


# -- unify --------------------------------------------------------------------

@unimplemented unify(s::Subs, p::BareNode,x::BareNode)
function unify(s::Subs, p::PNode,x::PNode)
    treenode(
        unify(s, get_simple_name(p),get_simple_name(x)),
        delayed_unify(s, get_tree(p),get_tree(x))
    )
end

unify(s::Subs, p::PVar,x::BareNode) = x
unify(s::Subs, p::Atom,x::Atom) = egal(p,x) ? x : (not_pgex!(s); nonematch)

#unify(s::Subs, p::Atom,x::PVar) = unify(not_pgex!(s), x,p)
unify(s::Subs, p::Atom,x::PVar) = (not_pgex!(s); unify(s, x,p))

unify(s::Subs, p::PVar,x::PVar) = (x.istemp && !p.istemp) ? p : x


pat_le(x,y) = (s=unite_ps(y,x)[2]; !s.disproved_p_ge_x)
pat_ge(x,y) = (s=unite_ps(x,y)[2]; !s.disproved_p_ge_x)
pat_eq(x,y) = pat_le(x,y) &&  pat_ge(x,y)
pat_lt(x,y) = pat_le(x,y) && !pat_ge(x,y)
pat_gt(x,y) = pat_ge(x,y) && !pat_le(x,y)


# -- TreePatterns -------------------------------------------------------------

unify(s::Subs, ::Anything,p::TreePattern) = p


type TuplePattern <: TreePattern
    t::(Pattern...)
end

# all TupplePatterns are more specific than ::Anything
unify(s::Subs, ps::TuplePattern,::Anything) = (not_pgex!(s); ps)

function unify(s::Subs, ps::TuplePattern,xs::TuplePattern)
    np, nx = length(ps.t), length(xs.t)
    if np != nx;  return nonematch;  end
    
    ys = cell(np)
    for k=1:np
        y = unite_step(s, ps.t[k],xs.t[k])
        if is(nonematch,y);  return nonematch;  end
        ys[k] = y
    end
    TuplePattern(tuple(ys...))
end


show(io::IO, p::TuplePattern) = print(io, enclose("TuplePattern(",p.t,")"))

function show_sig(io::IO, ps::TuplePattern)
    print(io, "(")
    for p in ps.t
        print_sig(io, p, ",")
    end
    print(io, ")")
end

function map_nodes(f::Function, p::TuplePattern) 
    TuplePattern(map(x->map_nodes(f,x), p.t))
end


function egal(p::TuplePattern, x::TuplePattern)
    (length(p.t) == length(x.t)) && egal(p.t,x.t)
end


# -- code_match ---------------------------------------------------------------

type MatchingCode
    nomatch_ret  # expr to be returned if match fails
    assigned_vars::Set{PVar}
    code::Vector

    MatchingCode(nomatch_ret) = new(nomatch_ret, Set{PVar}(), {})
end
get_varnames(c::MatchingCode) = {p.name for p in c.assigned_vars}

is_bound(c::MatchingCode, p::Atom) = true
is_bound(c::MatchingCode, p::PVar) = has(c.assigned_vars, p)

emit(c::MatchingCode, ex) = (push(c.code, ex); nothing)

function emit_predicate(c::MatchingCode, pred) 
    emit(c, :(  
        if !($pred)
            return ($c.nomatch_ret)
        end  
    ))
end

function emit_bind(c::MatchingCode, var::PVar, ex)
    @expect !has(c.assigned_vars, var)
    add(c.assigned_vars, var)
    sym::Symbol = code_value(var)
    emit(c, :( ($sym)=($ex) ))
    sym
end


code_match(p::PNode,xname::Symbol) = code_match(p,xname, :false)
function code_match(p::PNode,xname::Symbol, nomatch_ret)
    c = MatchingCode(nomatch_ret)
    code_match(c, p,xname)
    get_varnames(c), expr(:block, c.code)
end


code_value(p::Atom) = quot(p.value)
code_value(p::PVar) = p.name

function code_match(c::MatchingCode, p::BareNode, ex)
    if is_bound(c, p)
        emit_predicate(c, :( egal(($ex), ($code_value(p))) ))
        false, nothing
    else
        sym::Symbol = emit_bind(c, p, ex)
        true, sym
    end
end

function code_match(c::MatchingCode, p::TreeNode, ex)
    proceed, sym = code_match(c, p.simple_name, ex)
    if proceed
        code_match(c, p.tree, sym)
    end
end

function code_match(c::MatchingCode, p::TuplePattern, ex)
    np::Int = length(p.t)
    emit_predicate(c, :( isa(($ex), Tuple) && (length($ex) == ($np)) ))
    for k=1:np
        code_match(c, p.t[k], :( ($ex)[$k] ))
    end
end