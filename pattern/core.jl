
load("pattern/req.jl")
req("pattern/utils.jl")


# -- Domains ------------------------------------------------------------------

abstract Domain  ## A set of values 
type TypeDomain{T} <: Domain; end  ## The domain of values x such that x::T

domain{T}(::Type{T}) = TypeDomain{T}()

typealias Universe   TypeDomain{Any}
typealias NoneDomain TypeDomain{None}
const universe   = Universe()
const nonedomain = NoneDomain()

domtype{T}(::TypeDomain{T}) = T
has(d::TypeDomain, x) = isa(x, domtype(d))
(&){S,T}(::TypeDomain{S}, ::TypeDomain{T})=domain(tintersect(S,T))

show(io::IO, d::TypeDomain) = print(io, "domain(",domtype(d),")")
function code_contains{T}(::TypeDomain{T},xname::Symbol)
    :( isa(($xname),($quotevalue(T))) )
end


# -- PatternVar: Pattern variable (identity by object identity) ---------------

type PatternVar 
    name::Symbol
end


# -- Patterns -----------------------------------------------------------------


abstract Pattern ## supertype of all patterns 
type       NonePattern    <: Pattern; end  ## The pattern that matches nothing
abstract   RegularPattern <: Pattern       ## Patterns that match something
type         PVar           <: RegularPattern ## Pattern for var::domain
               var::PatternVar
               dom::Domain
 
               PVar(::PatternVar,::NoneDomain) = error("use nonematch instead")
               PVar(var::PatternVar, dom::Domain) = new(var, dom)
end
## Patterns with some structure specified; match only values::T
abstract     ValuePattern{T} <: RegularPattern 
abstract       Composite{T}    <: ValuePattern{T} ## Array/struct/etc patterns
type           Atom{T}         <: ValuePattern{T} ## Value without substructure
                 value::T
                 Atom(value::T) = (@assert isatom(value); new(value))
end
Atom{T}(value::T) = Atom{T}(value)

const nonematch = NonePattern()

## PVar creation ##
function pvar(var::PatternVar, dom::Domain) 
    is(dom, nonedomain) ? nonematch : PVar(var, dom)
end
pvar(name::Symbol, dom::Domain) = pvar(PatternVar(name), dom)
pvar{T}(v, ::Type{T}) = pvar(v, domain(T))
pvar( var::PatternVar) = pvar(var,  universe)
pvar(name::Symbol)     = pvar(name, universe)

function show(io::IO, p::PVar) 
    if is(p.dom, universe); print(io, "pvar(:$(p.var.name))")
    else                    print(io, "pvar(:$(p.var.name),$(p.dom))")
    end
end


## restrict the domain of a pattern
restrict( ::NonePattern, ::Domain) = nonematch
restrict(p::PVar, dom::Domain) = pvar(p.var, p.dom & dom)
restrict(p::Atom, dom::Domain) = has(dom, p.value) ? p : nonematch

restrict(p, dom::Domain) = restrict(aspattern(p), dom)
restrict{T}(p, ::Type{T}) = restrict(p, domain(T))


# -- Atom values --------------------------------------------------------------

# Only same-type atoms compare equal.
# Atom types T provide atom_eq(x::T, y::T)
isequal_atoms{T}(x::T, y::T) = atom_eq(x, y) 
isequal_atoms(x, y)          = false       

# provisional equivalence for atom types
atom_eq(x::Number, y::Number) = (x == y)
atom_eq(x, y) = is(x, y)

# provisional atom definition
isatom(::Number) = true
isatom(::String) = true
isatom(::Symbol) = true
isatom(::Any) = false