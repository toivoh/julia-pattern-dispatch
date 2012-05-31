
macro expect(pred)
    quote
        ($pred) ? nothing : error("expected: ", ($string(pred))", == true")
    end
end



abstract Pattern

abstract Aspect{T<:Pattern}
pattype{T}(::Aspect{T}) = T

type AspectKey
    name::Symbol
    aspect::Aspect
    deps::Vector{AspectKey}

    function AspectKey(name::Symbol, aspect::Aspect, deps)
        new(name, aspect, AspectKey[deps...])
    end
end


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

type AspectPattern <: Pattern
    key::AspectKey
    p::Pattern

    function AspectPattern(key::AspectKey, p::Pattern) 
        @expect isa(p, pattype(asp))
        new(key, p)
    end
end

# Label and collected (AspectKey, Pattern) pairs
type ObjectPattern <: Pattern
    label::Label
    factors::Vector{AspectPattern}
end

# Collected (index, Pattern) pairs for index properties
type IndexPattern{K} <: Pattern
    factors::Dict{K,ObjectPattern}
end


# -- Aspects ------------------------------------------------------------------

type TypeAspect <: Aspect{TypePattern}; end

abstract Property{T} <: Aspect{T}
abstract   IndexProperty{K} <: Property{IndexPattern{K}}

type FuncProperty  <: IndexProperty{Function}; end
type FieldProperty <: IndexProperty{Symbol};   end
type ApplyProperty <: IndexProperty{Tuple};    end
type RefProperty   <: IndexProperty{Tuple};    end


# -- Aspect DAG ---------------------------------------------------------------

type_asp  = AspectKey(:typeassert, TypeAspect(),    {})

func_asp  = AspectKey(:func,       FuncProperty(),  {type_asp})
field_asp = AspectKey(:getfield,   FieldProperty(), {type_asp})
apply_asp = AspectKey(:apply,      ApplyProperty(), {type_asp})

ref_asp   = AspectKey(:ref,        RefProperty(),   {type_asp, func_asp})
