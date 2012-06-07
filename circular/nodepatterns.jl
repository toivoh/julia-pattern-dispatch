
load("pattern/req.jl")
req("pretty/pretty.jl")
req("circular/utils.jl")


is_egal(x,y) = is(x,y)



abstract MaybePattern
type       NonePattern <: MaybePattern;  end
abstract   Pattern     <: MaybePattern
abstract     TreePattern <: Pattern
abstract     PNode       <: Pattern
abstract       BareNode    <: PNode

const nonematch = NonePattern()

show(io::IO, ::NonePattern) = print(io, "nonematch")

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

# treenode(simple_name, tree): create a TreeNode
# Takes ownership of tree if it's a DelayedTree
treenode(::NonePattern, ::TreePattern) = nonematch
function treenode(simple_name::BareNode, tree::TreePattern) 
    node = TreeNode(simple_name,tree)
    if isa(tree, DelayedTree)
        # take over ownership of the delayed tree 
        # ==> updates node when it has been formed
        tree.owner = node
    end
    node
end

show_sig(io::IO, p::TreeNode) = print_sig(io, p.simple_name, "~", p.tree)


type Atom{T} <: BareNode
    value::T
end
is_egal{T}(x::Atom{T},y::Atom{T}) = is_egal(x.value,y.value)

show(io::IO, p::Atom) = pprint(io, enclose("Atom(", p.value, ")"))
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

type DelayedTree <: TreePattern
    p::TreePattern
    x::TreePattern
    result::Union(TreePattern,NonePattern, Nothing)
    owner::TreeNode
    
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


function show_sig(io::IO, s::Subs)
    print(io, "Subs(", (s.disproved_p_ge_x ? "  " : ">="), ", {")
    let io=indented(io)
        for (k,v) in s.dict
            print(io, "\n", psig(k), " => ", psig(v), ", ")
        end
    end
    if !isempty(s.dict);  print(io, "\n");  end
    print(io, "}", s.delay_queue, ")")
end

map_nodes(f::Function, p::PNode) = f(p)


# -- unite --------------------------------------------------------------------

function unite(p::PNode, x::PNode)
    s = Subs()
    y = unite(s, p,x)
    while !isempty(s.delay_queue)
        d = pop(s.delay_queue)
        p, x = undelayed(d.p), undelayed(d.x)

        # unify the tree patterns
        local y = unify(s, p,x)
        if is(y,nonematch);  return nonematch;  end

        d.result = y
        d.owner.tree = y  # update owner
    end
    y = make_node_tree(s,y)
    y, s
end

function unite(s::Subs, p::PNode, x::PNode)
    p, x = lookup(s,p), lookup(s,x)
    if is_egal(p,x);  return x;  end
    
    y = unify(s, p,x)
    if is(y,nonematch);  return nonematch;  end
    s[p] = s[x] = y    
end

make_node_tree(s::Subs, ::NonePattern) = nonematch
make_node_tree(s::Subs, p::PNode) = make_node_tree(s,Set{TreeNode}(), p)
function make_node_tree(s::Subs,nodes::Set{TreeNode}, p::PNode)
    p=lookup(s,p)
    if isa(p,BareNode)
        return p
    elseif isa(p,TreeNode)
        if has(nodes,p)
            return p.simple_name
        else
            add(nodes, p)
            return treenode(p.simple_name, 
                            map_nodes(p->make_node_tree(s,nodes,p), p.tree))
        end
    else
        error("unexpected!")
    end
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
    else;                                    treenode(simple_name, x.tree)
    end
end
# NB! Assumes that any tree is more specific than no tree:
unify(s::Subs, p::TreeNode,x::BareNode) = unify(not_pgex!(s), x,p)


unify(s::Subs, p::PVar,x::BareNode) = x
unify(s::Subs, p::Atom,x::Atom) = is_egal(p,x) ? x : (not_pgex!(s); nonematch)

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
