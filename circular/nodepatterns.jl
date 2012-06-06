
load("pattern/req.jl")
req("pretty/pretty.jl")
req("circular/utils.jl")


is_egal(x,y) = is(x,y)



abstract MaybePattern
type       NonePattern  <: MaybePattern;  end
abstract   Pattern      <: MaybePattern
abstract     TreePattern <: Pattern
abstract     PNode <: Pattern
abstract       BareNode <: PNode

const nonematch = NonePattern()


type TreeNode <: PNode
    simple_name::BareNode
    tree::TreePattern
end

treenode(           ::NonePattern,  ::TreePattern) = nonematch
treenode(simple_name::BareNode, tree::TreePattern) = TreeNode(simple_name,tree)


type Atom{T} <: BareNode
    value::T
end
is_egal{T}(x::Atom{T},y::Atom{T}) = is_egal(x.value,y.value)

show(io::IO, p::Atom) = pprint(io, enclose("Atom(", p.value, ")"))

type PVar <: BareNode
    name::Symbol
    istemp::Bool
end
PVar(name::Symbol) = PVar(name, false)

function show(io::IO, p::PVar) 
    print(io, p.istemp ? "PVar(:$(p.name),true)" : "PVar(:$(p.name))")
end

type DelayedTree <: TreePattern
    p::TreePattern
    x::TreePattern
    result::Union(TreePattern,NonePattern, Nothing)
    
    DelayedTree(p::TreePattern, x::TreePattern) = new(p, x, nothing)
end

undelayed(p::DelayedTree) = p.result::TreePattern
undelayed(p::TreePattern) = p


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
    if !has(s.dict, p);  p
    else;                s.dict[p] = lookup(s, s.dict[p])        
    end
end

function assign(s::Subs, x::PNode, p::PNode)
    @expect !has(s.dict, p)
    if !is_egal(x,p)
        s.dict[p] = x
    end
end

function delayed_unify(s::Subs, p::TreePattern,x::TreePattern)
    d = DelayedTree(p,x)
    enqueue(s.delay_queue, d)
    d
end


# -- unite --------------------------------------------------------------------

function unite(p::PNode, x::PNode)
    s = Subs()
    y = unite(s, p,x)
    while !isempty(s.delay_queue)
        d = pop(s.delay_queue)
        p, x = undelayed(d.p), undelayed(d.x)

        # unify the tree patterns
        y = unify(s, p,x)
        if is(y,nonematch);  return nonematch;  end

        d.result = y
    end
    y, s  # todo: apply all substitutions
end

function unite(s::Subs, p::PNode, x::PNode)
    p, x = lookup(s,p), lookup(s,x)
    if is_egal(p,x);  return x;  end
    
    y = unify(s, p,x)
    if is(y,nonematch);  return nonematch;  end
    s[p] = s[x] = y    
end

# -- unify --------------------------------------------------------------------

function unify(s::Subs, p::TreeNode,x::TreeNode)
    treenode(unify(s, p.simple_name,x.simple_name),
        delayed_unify(s, p.tree,x.tree))
end

function unify(s::Subs, p::BareNode,x::TreeNode)    
#    treenode(unify(s, p,x.simple_name), x.tree)
    simple_name = unify(s, p,x.simple_name)
    if is_egal(simple_name, x.simple_name);  x
    else;                               treenode(simple_name, x.tree)
    end
end
# NB! Assumes that any tree is more specific than no tree:
unify(s::Subs, p::TreeNode,x::BareNode) = unify(not_pgex!(s), x,p)


unify(s::Subs, p::PVar,x::BareNode) = x
unify(s::Subs, p::Atom,x::Atom)     = is_egal(p,x) ? x : nonematch

#unify(s::Subs, p::Atom,x::PVar) = unify(not_pgex!(s), x,p)
unify(s::Subs, p::Atom,x::PVar) = (not_pgex!(s); unify(s, x,p))


# -- TreePatterns -------------------------------------------------------------

type TuplePattern <: TreePattern
    t::(Pattern...)
end

function unify(s::Subs, ps::TuplePattern,xs::TuplePattern)
    np, nx = length(ps.t), length(xs.t)
    if np != nx;  return nonematch;  end
    
    ys = cell(np)
    for k=1:np
        y = unite(s, ps.t[k],xs.t[k])
        if is(nonematch,y);  return nonematch;  end
        ys[k] = y
    end
    TuplePattern(tuple(ys...))
end


show(io::IO, p::TuplePattern) = print(io, enclose("TuplePattern(",p.t,")"))
