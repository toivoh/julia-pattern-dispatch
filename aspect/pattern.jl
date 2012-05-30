
abstract Pattern
abstract Label
abstract Aspect{T<:Pattern}

## Labels ##

type Var <: Label
    name::Symbol
end
type Atom{T} <: Label
    value::T
end


## Patterns ##

type TypePattern <: Pattern
    T
end

type AspectEntry{T<:Pattern}
    key::Aspect{T}
    p::T
end

type ObjectPattern <: Pattern
    label::Label
    factors::Vector{AspectEntry}
end

type AssocPattern{K}
    factors::Dict{K,ObjectPattern}
end


## Aspects ##

type TypeAspect <: Aspect{TypePattern}; end

abstract Property{T<:Pattern} <: Aspect{T}
abstract   AssocProperty{K} <: Property{AssocPattern{K}}

type FuncProperty   <: AssocProperty{Function}; end
type IndexProperty  <: AssocProperty{Tuple};    end
type FieldsProperty <: AssocProperty{Symbol};   end
type ApplyProperty  <: AssocProperty{Tuple};    end

