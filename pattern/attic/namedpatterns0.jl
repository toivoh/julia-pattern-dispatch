
load("pattern/req.jl")
#req("pretty/pretty.jl")
req("circular/utils.jl")

abstract Pattern
type       NonePattern        <: Pattern;  end
abstract   RegularPattern     <: Pattern
abstract     TreePattern      <: RegularPattern
abstract     NamedPattern     <: RegularPattern
abstract       PresentPattern <: NamedPattern
abstract         IdPattern    <: PresentPattern
abstract           PrimId     <: IdPattern

const nonematch = NonePattern()

type DelayedProduct <: NamedPattern
    factors::Vector{RegularPattern}
end

type NamedTree <: PresentPattern
    id::IdPattern
    tree::TreePattern
end

type ProductId <: IdPattern
    prime_id::PrimId
    ids::Set{PrimId}
end

type PVar <: PrimId
    name::Symbol
end

type Atom{T} <: PrimId
    value::T
end


get_ids(p::ProductId) = p.ids
get_ids(p::PrimId)    = Set{PrimId}(p)

# get_id(p::NamedTree) = p.id
# get_id(p::IdPattern) = p
# get_tree(p::NamedTree) = p.tree
# get_tree(p::IdPattern) = anything  # todo: define anything. Where?


#abstract Subs
typealias SubsDict Dict{NamedPattern,NamedPattern}
type Subs
    dict::SubsDict
    Subs() = new(SubsDict())
end

## NonePattern vs RegularPattern ##
# todo: catch this nonematch return and make sure it propagates
unify(s::Subs, args::Pattern...) = nonematch  # catches all NonePattern cases
@unimplemented unify(s::Subs, args::RegularPattern...)

## RegularPattern vs RegularPattern ##

### TreePattern vs TreePattern ###
unify(s::Subs, p::TreePattern) = p
# supplied by TreePattern implementations
@unimplemented unify(s::Subs, p::TreePattern,x::TreePattern)

### The three other cases ###
unify(s::Subs, p::TreePattern, x::NamedPattern) = unify_named(s,   p ,s[x])
unify(s::Subs, p::NamedPattern,x::TreePattern)  = unify_named(s, s[p],  x )
unify(s::Subs, p::NamedPattern,x::NamedPattern) = unify_named(s, s[p],s[x])

## unify_named ##

unify_named(s::Subs, p::RegularPattern,x::RegularPattern) = delayedprod(s, p,x)

redirect(s::Subs, p::TreePattern, target::NamedPattern) = nothing
function redirect(s::Subs, p::NamedPattern, target::NamedPattern)
    @expect !has(s, p)
    s.dict[p] = target
end

get_factors(p::RegularPattern) = RegularPattern[p]
get_factors(p::DelayedProduct) = p.factors

# if p or x are NamedPatterns, they must be unbound in s
function delayedprod(s::Subs, p::RegularPattern, x::RegularPattern)
    factors = RegularPattern[get_factors(p)..., get_factors(x)...]
    
    if isa(p, DelayedPattern); target = p
    elseif isa(x, DelayedPattern); target = x
    else target = DelayedPattern([])
    end

    target.factors = factors
    redirect(s, p,target)
    redirect(s, x,target)
end

## NamedTree vs IdPattern ##

function unify_named(s::Subs, p::NamedTree,x::IdPattern)
    s[p] = NamedTree(unify_named(s, p.id,x), p.tree)
end
function unify_named(s::Subs, p::IdPattern,x::NamedTree)
    s[p] = NamedTree(unify_named(s, p,x.id), x.tree)
end

## IdPattern vs IdPattern ##

primeid(x::Atom,   y::Atom)   = is_egal(x,y) ? x : nonematch
primeid(x::Atom,   y::PrimId) = x
primeid(x::PrimId, y::PrimId) = y

function unify_named(s::Subs, p::IdPattern, x::IdPattern)
    prime = primeid(p, x)
    if is(nonematch, prime);  return nonematch;  end
    ids = union(get_ids(p), get_ids(x))
    n = length(ids);
    @expect n >= 1
    if >= 2;  return ProductId(prime, ids)
    else;     return prime
    end
end


