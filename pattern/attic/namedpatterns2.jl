
load("pattern/req.jl")
#req("pretty/pretty.jl")
req("circular/utils.jl")

abstract MaybePattern
type       NonePattern  <: MaybePattern;  end
abstract   Pattern      <: MaybePattern
abstract     TreePattern  <: Pattern
abstract     NamedPattern <: Pattern
abstract       NamedTree    <: NamedPattern
abstract       IdPattern    <: NamedPattern

const nonematch = NonePattern


# -- NamedPatterns ------------------------------------------------------------

type IdTree <: NamedTree
    id::IdPattern
    tree::TreePattern
end

type DelayedProd <: NamedTree
    ##factors::Vector{NamedPattern}
    p::NamedPattern
    x::NamedPattern
end

type Atom{T} <: IdPattern
    value::T
end
type PVar <: IdPattern
    name::Symbol
    istemp::Bool
end


# -- Subs ---------------------------------------------------------------------

typealias SubsDict Dict{NamedPattern,NamedPattern}
type Subs
    dict::SubsDict
    delay_stack::Vector{DelayedProd}

    Subs() = new(SubsDict())
end

function lookup(s::Subs, p::NamedPattern)
    if !has(s.dict, p);  p
    else;                s.dict[p] = lookup(s, s.dict[p])        
    end
end

function assign(s::Subs, target::NamedPattern, p::NamedPattern)
    @expect !has(s, p)
    s.dict[p] = target
end

redirect(s::Subs, p::TreePattern, target::SubsPattern) = nothing
redirect(s::Subs, p::SubsPattern, target::SubsPattern) = (s[p] = target)

function delayedprod(s::Subs, p::NamedPattern, x::NamedPattern)
    prod = DelayedProd(p, x)
    push(s.delay_stack, prod)
    prod
end

# -- unify --------------------------------------------------------------------

function unify(p::NamedPattern, x::NamedPattern)
    s = Subs()
    delayedprod(s, p,x)
    while !isempty(s.delay_stack)
        dp = pop(s.delay_stack)
        p = unify(s, s[dp.p],s[dp.x])
        s[dp] = p
    end
end


unify(s::Subs, ::NonePattern, args...) = nonematch

unify(s::Subs, p::TreePattern) = p
@unimplemented unify(s::Subs, p::TreePattern,x::TreePattern)

unify(s::Subs, ps::NamedPattern...) = unite(s, map(p->lookup(s,p), ps)...)

unite(s::Subs, p::PVar, x::IdPattern) = (s[p] = x)
unite(s::Subs, p::Atom, x::Atom) = is(p,x) ? x : nonematch

unite(s::Subs, p::NamedPattern, x::NamedPattern) = delayedprod(s, p,x)



# -- TreePatterns -------------------------------------------------------------

type TuplePattern <: TreePattern
    t::(Pattern...)
end

function unify(s::Subs, ps::TuplePattern,xs::TuplePattern)
    np, nx = length(ps), length(xs)
    if np != nx;  return nonematch;  end
    
    ys = cell(np)
    for k=1:np
        y = unify(s, ps[k],xs[k])
        if is(nonematch,y);  return nonematch;  end
        ys[k] = y
    end
    tuple(ys...)
end
