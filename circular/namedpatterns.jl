
load("pattern/req.jl")
#req("pretty/pretty.jl")
req("circular/utils.jl")

abstract MaybePattern
type       NonePattern    <: MaybePattern;  end
abstract   Pattern        <: MaybePattern
abstract     FeaturePattern <: Pattern
abstract       TreePattern    <: FeaturePattern
abstract       NamedPattern   <: FeaturePattern
abstract     IdPattern      <: Pattern


const nonematch = NonePattern


type NamedTree <: NamedPattern
    id::IdPattern
    tree::TreePattern
end
type DelayedTree <: NamedPattern
    factors::Vector{Pattern}
end

get_factors(p::FeaturePattern) = Pattern[p]
get_factors(p::DelayedTree)    = p.factors


# -- Subs ---------------------------------------------------------------------

typealias SubsPattern Union(NamedPattern, IdPattern)
typealias SubsDict Dict{SubsPattern,SubsPattern}
type Subs
    dict::SubsDict
    Subs() = new(SubsDict())
end

function lookup(s::Subs, p::Pattern)
    if !has(s.dict, p);  p
    else;                s.dict[p] = lookup(s, s.dict[p])        
    end
end

redirect(s::Subs, p::TreePattern, target::SubsPattern) = nothing
redirect(s::Subs, p::SubsPattern, target::SubsPattern) = (s[p] = target)
function assign(s::Subs, target::SubsPattern, p::SubsPattern)
    @expect !has(s, p)
    s.dict[p] = target
end

# -- unify --------------------------------------------------------------------


## NonePattern vs Pattern ##

# todo: catch this nonematch return and make sure it propagates
# catches all NonePattern cases
unify(s::Subs, args::MaybePattern...) = nonematch 
unify(s::Subs, args::Pattern...)      = unify_rep(s, map(p->lookup(s,p), args))

### TreePattern vs TreePattern ###
unify_rep(s::Subs, p::TreePattern) = p
# supplied by TreePattern implementations
@unimplemented unify_rep(s::Subs, p::TreePattern,x::TreePattern)

### other cases: delayed products ###

unify_rep(s::Subs, p::FeaturePattern,x::FeaturePattern) = delayedprod(s, p,x)
unify_rep(s::Subs, p::DelayedTree,   x::IdPattern)      = delayedprod(s, p,x)

# if p or x are NamedPatterns, they must be unbound in s
function delayedprod(s::Subs, p::FeaturePattern, x::FeaturePattern)
    factors = [get_factors(p), get_factors(x)]
    
    if     isa(p, DelayedTree); target = p
    elseif isa(x, DelayedTree); target = x
    else;                       target = DelayedTree([])
    end

    target.factors = factors
    redirect(s, p,target)
    redirect(s, x,target)
end


## FeaturePattern vs IdPattern ##

unify_rep(s::Subs, p::TreePattern, x::IdPattern) = (s[x] = NamedTree(x, p))
function unify_rep(s::Subs, p::NamedTree, x::IdPattern)
    # note: unify_rep below does not look up p.id, as that would give p!
    y = namedtree(unify_rep(s, p.id,x), p.tree)
    s[p] = s[x] = y
end



# -- IdPattern ----------------------------------------------------------------

abstract PrimId <: IdPattern

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

primeid(x::Atom,   y::Atom)   = is_egal(x,y) ? x : nonematch
primeid(x::Atom,   y::PrimId) = x
primeid(x::PrimId, y::PrimId) = y

function unify_rep(s::Subs, p::IdPattern, x::IdPattern)
    prime = primeid(p, x)
    if is(nonematch, prime);  return nonematch;  end
    ids = union(get_ids(p), get_ids(x))
    n = length(ids);
    @expect n >= 1
    if >= 2;  return ProductId(prime, ids)
    else;     return prime
    end
end


