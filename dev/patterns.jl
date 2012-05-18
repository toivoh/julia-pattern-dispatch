
load("utils/req.jl")
req("utils/utils.jl")

# -- Atoms --------------------------------------------------------------------

# provisional atom definition
isatom(::Number) = true
isatom(::String) = true
isatom(::Symbol) = true
isatom(::Any) = false

# Only same-type atoms compare equal.
# Atom types T provide atom_eq(x::T, y::T)
isequal_atoms{T}(x::T, y::T) = atom_eq(x, y) 
isequal_atoms(x, y)          = false       

# provisional equivalence for atom types
atom_eq(x::Number, y::Number) = (x == y)
atom_eq(x, y) = is(x, y)


# -- Containers ---------------------------------------------------------------

is_containertype(T) = false
is_container(x) = is_containertype(typeof(x))

get_containertype{T}(::Type{T}) = error("not a container type: ", T)
get_containertype(x) = get_containertype(typeof(x))

isequal_type(S,T) = (S <: T)&&(T <: S)  # todo: better way to implement this?
function isequiv_containers(x,y)
    (isequal_type(get_containertype(x),get_containertype(y)) && 
     isequal(container_shape(x),container_shape(y)))
end

map_container(f) = error("need at least one container to know container type!")

## Tuple as container type ##
is_containertype( ::Tuple) = true
get_containertype(::Tuple) = Tuple
container_shape( x::Tuple) = length(x)

map_container(f, args::Tuple...) = map(f, args...)
ravel_container(x::Tuple) = x
function code_ravel_container(x::Tuple, xname::Symbol) 
 { :(($xname)[$k]) for k=1:length(x) }
end

## Array as container type ##
typealias NTArray{N,T} Array{T,N}
is_containertype{T,N}(::Type{Array{T,N}}) = true
get_containertype{T,N}(::Type{Array{T,N}}) = NTArray{N}
container_shape(x::Array) = size(x)

map_container(f, args::Array...) = map(f, args...)
ravel_container(x::Array) = x[:]
function code_ravel_container(x::Array, xname::Symbol) 
 { :(($xname)[$k]) for k=1:numel(x) }
end


# -- Patterns -----------------------------------------------------------------

## Domain: a set of values ##
abstract Domain

## StrictPattern: supertype of all pattern types that cannot be values ##
# For given pattern variables values, a pattern matches at most one value.
abstract StrictPattern

## NonePattern: The pattern that matches nothing ##
type NonePattern <: StrictPattern; end  
const nonematch = NonePattern()

show(io::IO, ::NonePattern) = print(io, "nonematch")

## PVar: Pattern variable that matches any value; but only one at a time ##
# P::PVar and Q::PVar are the same variable only if is(P,Q)
type PVar <: StrictPattern
    name::Symbol
end

# Create a new pattern variable with the given name
pvar(name::Symbol) = PVar(name)

show(io::IO, p::PVar) = print(io, "pvar(:$(p.name))")

## DomPattern: Intersection of a pattern and a domain ##
type DomPattern <: StrictPattern
    p  # any kind of pattern
    dom::Domain

    function DomPattern(p, dom::Domain)
        # should avoid confusion; don't need/want patterns that are domains
        @expect !isa(p, Domain)  
        new(p, dom)
    end
end

restrict(p::DomPattern, dom::Domain) = restrict(dintersect(dom, p.dom), p.p)
restrict(p, dom::Domain) = DomPattern(p, dom)
