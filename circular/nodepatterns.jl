
abstract MaybePattern
type       NonePattern  <: MaybePattern;  end
abstract   Pattern      <: MaybePattern
abstract     TreePattern <: Pattern
abstract     PNode <: Pattern
abstract       BareNode <: PNode

const nonematch = NonePattern


type TreeNode <: PNode
    simple_name::BareNode
    tree::TreePattern
end

treenode(           ::NonePattern,  ::TreePattern) = nonematch
treenode(simple_name::BareNode, tree::TreePattern) = TreeNode(simple_name,tree)


type Atom{T} <: BareNode
    value::T
end
type PVar <: BareNode
    name::Symbol
    istemp::Bool
end
PVar(name::Symbol) = Pvar(name, false)


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
    delay_queue::Vector{DelayedTree}

    Subs() = new(SubsDict(),[])
end

function lookup(s::Subs, p::PNode)
    if !has(s.dict, p);  p
    else;                s.dict[p] = lookup(s, s.dict[p])        
    end
end

function assign(s::Subs, x::PNode, p::PNode)
    @expect !has(s, p)
    s.dict[p] = x
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
        if is(y,nonematch);  return  nonematch;  end

        d.result = y
    end
    s, y  # todo: apply all substitutions
end

function unite(s::Subs, p::PNode, x::PNode)
    p, x = lookup(s,p), lookup(s,x)
    if is(p,x);  return x;  end
    
    y = unify(s, p,x)
    s[p] = s[x] = y    
end

# -- unify --------------------------------------------------------------------

function unify(s::Subs, p::TreeNode,x::TreeNode)
    treenode(unify(s, p.simple_name,x.simple_name),
        delayed_unify(s, p.tree,x.tree))
end

function unify(s::Subs, p::BareNode,x::TreeNode)
    treenode(unify(s, p,x.simple_name), x.tree)
end

unify(s::Subs, p::PVar,x::BareNode) = x
unify(s::Subs, p::Atom,x::Atom)     = is_egal(p,x) ? x : nonematch


# -- TreePatterns -------------------------------------------------------------

type TuplePattern <: TreePattern
    t::(Pattern...)
end

function unify(s::Subs, ps::TuplePattern,xs::TuplePattern)
    np, nx = length(ps), length(xs)
    if np != nx;  return nonematch;  end
    
    ys = cell(np)
    for k=1:np
        y = unite(s, ps[k],xs[k])
        if is(nonematch,y);  return nonematch;  end
        ys[k] = y
    end
    tuple(ys...)
end
