

# Only same-type atoms compare equal.
# Atom types T provide atom_eq(x::T, y::T)
isequal_atoms{T}(x::T, y::T) = atom_eq(x, y) 
isequal_atoms(x, y)          = false       

# provisonal equivalence for atom types
atom_eq(x::Number, y::Number) = (x == y)
atom_eq(x, y) = is(x, y)


## Domain: a set of values ##
abstract Domain

## Pattern: supertype of all pattern types that cannot be values ##
# For given pattern variables values, a Pattern matches at most one value.
abstract Pattern

## NonePattern: The pattern that matches nothing ##
type NonePattern <: Pattern; end  
const nonematch = NonePattern()

show(io::IO, ::NonePattern) = print(io, "nonematch")

## PVar: Pattern variable that matches any value; but only one at a time ##
# P::PVar and Q::PVar are the same variable only if is(P,Q)
type PVar <: Pattern
    name::Symbol
end

# Create a new pattern variable with the given name
pvar(name::Symbol) = PVar(name)

show(io::IO, p::PVar) = print(io, "pvar(:$(p.name))")

## DomPattern: Intersection of a pattern and a domain ##
type DomPattern <: Pattern
    p  # any kind of pattern
    dom::Domain

    function DomPattern(p, dom::Domain)
        # should avoid confusion; don't need/want patterns that are domains
        @expect !isa(p, Domain)  
        new(p, dom)
    end
end
