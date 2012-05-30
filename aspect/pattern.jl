
abstract Pattern
abstract Aspect{T<:Pattern}

type AspectKey{T<:Pattern}
    name::Symbol
    aspect::Aspect{T}
    deps::Vector{AspectKey}

    function AspectKey(name::Symbol, aspect::Aspect{T}, deps)
        new(name, aspect, AspectKey[deps...])
    end
end
AspectKey{T}(name, aspect::Aspect{T}, deps) = AspectKey{T}(name, aspect, deps)


# -- Labels -------------------------------------------------------------------

## Label for an ObjectPattern ##
abstract Label

type Var <: Label
    name::Symbol
end
type Atom{T} <: Label
    value::T
end


# -- Patterns -----------------------------------------------------------------

# typeassert(x, T)
type TypePattern <: Pattern
    T
end

type AspectEntry{T<:Pattern}
    key::AspectKey{T}
    p::T
end
# Label and collected (AspectKey, Pattern) pairs
type ObjectPattern <: Pattern
    label::Label
    factors::Vector{AspectEntry}
end

# Collected (index, Pattern) pairs for index properties
type IndexPattern{K} <: Pattern
    factors::Dict{K,ObjectPattern}
end


# -- Aspects ------------------------------------------------------------------

type TypeAspect <: Aspect{TypePattern}; end

abstract Property{T<:Pattern} <: Aspect{T}
abstract   IndexProperty{K} <: Property{IndexPattern{K}}

type FuncProperty   <: IndexProperty{Function}; end
type FieldProperty  <: IndexProperty{Symbol};   end
type ApplyProperty  <: IndexProperty{Tuple};    end
type RefProperty    <: IndexProperty{Tuple};    end


# -- Aspect DAG ---------------------------------------------------------------

type_asp  = AspectKey(:typeassert, TypeAspect(),    {})

func_asp  = AspectKey(:func,       FuncProperty(),  {type_asp})
field_asp = AspectKey(:getfield,   FieldProperty(), {type_asp})
apply_asp = AspectKey(:apply,      ApplyProperty(), {type_asp})

ref_asp   = AspectKey(:ref,        RefProperty(),   {type_asp, func_asp})
