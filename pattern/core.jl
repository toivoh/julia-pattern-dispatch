
load("pattern/req.jl")
req("pattern/utils.jl")


# -- Domains ------------------------------------------------------------------

abstract Domain  ## A set of values 
type TypeDomain{T} <: Domain; end  ## The domain of values x such that x::T

domain{T}(::Type{T}) = TypeDomain{T}()
domain(T::Tuple)     = TypeDomain{T}()

typealias Universe   TypeDomain{Any}
typealias NoneDomain TypeDomain{None}
const universe   = Universe()
const nonedomain = NoneDomain()

domtype{T}(::TypeDomain{T}) = T
has(d::TypeDomain, x) = isa(x, domtype(d))
(&){S,T}(::TypeDomain{S}, ::TypeDomain{T})=domain(tintersect(S,T))

<={S,T}(x::TypeDomain{S},y::TypeDomain{T}) = S <: T
<( x::TypeDomain, y::TypeDomain) = (x <= y) && !(y <= x)
>=(x::TypeDomain, y::TypeDomain) = y <= x
>( x::TypeDomain, y::TypeDomain) = y <  x

show(io::IO, d::TypeDomain) = print(io, "domain(",domtype(d),")")
code_contains(::Universe,::Symbol) = :true
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

show(io::IO, ::NonePattern) = print(io, "nonematch")

show_unpatterned(x) = show_unpatterned(OUTPUT_STREAM, x)
show_unpatterned(io::IO, x) = show(io, x)
show_unpatterned(io::IO, dom::TypeDomain) = print(io, domtype(dom))
function show_unpatterned(io::IO, p::PVar)
    print(io, p.var.name)
    if !is(p.dom,universe)
        print(io, "::")
        show_unpatterned(io, p.dom)
    end
end
show_unpatterned(io::IO, p::Atom) = show(io, p.value)

isequal(x::Pattern, y::Pattern) = is(x,y)
isequal(x::PVar, y::PVar) = is(x.var, y.var) && isequal(x.dom, y.dom)
isequal(x::Atom, y::Atom) = isequal_atoms(x.value, y.value)

dom( ::NonePattern) = nonedomain
dom(p::PVar) = p.dom
dom{T}(p::Atom{T}) = domain(T)

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
function restrict(p::Pattern, dom::Domain)
    if is(dom, universe); p
    else error("unimplemented: restrict(", typeof(p),", ", typeof(dom),")")
    end
end

#restrict(p, dom::Domain) = restrict(aspattern(p), dom)
function restrict(p, dom::Domain)
    pp = aspattern(p)
    if typeof(pp) != typeof(p); restrict(pp, dom); end
    error("unimplemented: restrict(", typeof(p),", ", typeof(dom),")")
end
restrict{T}(p, ::Type{T}) = restrict(p, domain(T))


# -- Atom values --------------------------------------------------------------

# Only same-type atoms compare equal.
# Atom types T provide atom_eq(x::T, y::T)
isequal_atoms{T}(x::T, y::T) = atom_eq(x, y) 
isequal_atoms(x, y)          = false       

# provisional equivalence for atom types
atom_eq(x::Number, y::Number) = (x == y)
atom_eq(x::Array, y::Array) = isequal(x, y)  # consider: too loose?
atom_eq(x, y) = is(x, y)

# provisional atom definition
isatom(::Number) = true
isatom(::String) = true
isatom(::Symbol) = true
isatom(::Nothing) = true
isatom(::Any) = false
