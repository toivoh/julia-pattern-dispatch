
macro expect(pred)
    quote
        ($pred) ? nothing : error("expected: ", ($string(pred))", == true")
    end
end

quot(value) = expr(:quote, value)



# -- Basic definitions ------------------------------------------------------

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


# -- Patterns -----------------------------------------------------------------

type TypePattern <: Pattern
    T::Union(Type, Tuple)
end
code_match(c, p::TypePattern,ex) = emit_pred(c,:( isa(($ex),($quot(p.T))) ))

type AspectPattern <: Pattern
    key::AspectKey
    p::Pattern

    function AspectPattern(key::AspectKey, p::Pattern) 
        @expect isa(p, pattype(key.aspect))
        new(key, p)
    end
end
code_match(c, p::AspectPattern,ex) = code_match(c, p.p,code_get(c,p.key, ex))

## Label for an ObjectPattern ##
abstract Label

type Var <: Label
    name::Symbol
end
type Atom{T} <: Label
    value::T
end

# Label and collected (AspectKey, Pattern) pairs
type ObjectPattern <: Pattern
    label::Label
    factors::Vector{AspectPattern} # assumed topsorted by aspect key
end
function code_match(c, po::ObjectPattern,ex)
    emit_bind(c, po.label,ex)
    for p in po.factors;  code_match(c, p,ex);  end
end

# Collected (index, Pattern) pairs for index properties
type IndexPattern{K} <: Pattern
    factors::Dict{K,ObjectPattern}
end
function code_match(c, ps::IndexPattern,prop)
    for (key, p) in ps.factors;  code_match(c, p,code_get(c,prop, key));  end
end


# -- Aspects ------------------------------------------------------------------

type TypeAspect <: Aspect{TypePattern}; end
code_get(c,::TypeAspect, ex) = ex

abstract Property{T} <: Aspect{T}
abstract   IndexProperty{K} <: Property{IndexPattern{K}}

## Bundles an IndexProperty with a value expression until it can be indexed ##
type PropObj{T<:IndexProperty}
    prop::T
    ex
end
PropObj{T}(aspect::T, ex) = PropObj{T}(aspect::T, ex)
code_get(c,prop::IndexProperty, ex) = PropObj(prop, ex)

## Index properties ##
type FuncProperty  <: IndexProperty{Function}; end
type FieldProperty <: IndexProperty{Symbol};   end
type RefProperty   <: IndexProperty{Tuple};    end
type ApplyProperty <: IndexProperty{Tuple};    end

code_get(c, x::PropObj{FuncProperty},  key::Function) = :( ($key)($x.ex)    )
code_get(c, x::PropObj{FieldProperty}, key::Symbol)   = :( ($x.ex).($key)   )
code_get(c, x::PropObj{RefProperty},   key::Tuple)    = :( ($x.ex)[$key...] )
code_get(c, x::PropObj{ApplyProperty}, key::Tuple)    = :( ($x.ex)($key...) )


# -- Aspect DAG ---------------------------------------------------------------

type_asp  = AspectKey(:typeassert, TypeAspect(),    {})

func_asp  = AspectKey(:func,       FuncProperty(),  {type_asp})
field_asp = AspectKey(:getfield,   FieldProperty(), {type_asp})
apply_asp = AspectKey(:apply,      ApplyProperty(), {type_asp})

ref_asp   = AspectKey(:ref,        RefProperty(),   {type_asp, func_asp})
