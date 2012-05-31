
load("pattern/req.jl")
load("pretty/pretty.jl")


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

function show(io::IO, p::AspectPattern)
    pprint(io, "AspectPattern(", indent(p.key.name, ", ", p.p), ")")
end


## Label for an ObjectPattern ##
abstract Label

type Var <: Label
    name::Symbol
end
show(io::IO, var::Var) = print(io, "Var(:", var.name, ")")
type Atom{T} <: Label
    value::T
end

# Label and collected (AspectKey, Pattern) pairs
type ObjectPattern <: Pattern
    label::Label
    factors::Vector{AspectPattern} # assumed topsorted by aspect key
end
# todo: topsort factors!
ObjectPattern(label::Label, ps) = ObjectPattern(label, AspectPattern[ps...])

function code_match(c, po::ObjectPattern,ex)
    symbol = emit_bind(c, po.label,ex)
    for p in po.factors;  code_match(c, p,symbol);  end
end

function show(io::IO, p::ObjectPattern) 
    pprint(io, "ObjectPattern(", 
           indent(
               p.label, ", [", #indent(
                   delim_list(p.factors, '\n', ','),
               #), 
               "]"
#               PNest(io->showall(io, p.factors))
           ), 
       ")")
end


# Collected (index, Pattern) pairs for index properties
type IndexPattern{K} <: Pattern
    factors::Dict{K,ObjectPattern}
end
#IndexPattern{K}(factors::Dict{K,ObjectPattern}) = IndexPattern{K}(factors)

function code_match(c, ps::IndexPattern,prop)
    for (key, p) in ps.factors;  code_match(c, p,code_get(c,prop, key));  end
end


# -- Aspects ------------------------------------------------------------------


code_get(c,key::AspectKey, ex) = code_get(c,key.aspect, ex)


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

code_get(c, x::PropObj{FuncProperty},  key::Function) = :( ($quot(key))($x.ex))
code_get(c, x::PropObj{FieldProperty}, key::Symbol)   = :( ($x.ex).($key)   )
code_get(c, x::PropObj{RefProperty},   key::Tuple)    = :( ($x.ex)[$key...] )
code_get(c, x::PropObj{ApplyProperty}, key::Tuple)    = :( ($x.ex)($key...) )


# -- Aspect DAG ---------------------------------------------------------------

type_asp  = AspectKey(:type_asp,  TypeAspect(),    {})

func_asp  = AspectKey(:func_asp,  FuncProperty(),  {type_asp})
field_asp = AspectKey(:field_asp, FieldProperty(), {type_asp})
apply_asp = AspectKey(:apply_asp, ApplyProperty(), {type_asp})

ref_asp   = AspectKey(:ref_asp,   RefProperty(),   {type_asp, func_asp})



# -- Matching code generation -------------------------------------------------

type CMContext
    assigned_vars::Set{Var}
    code::Vector
    CMContext() = new(Set{Var}(), {})
end

emit(c::CMContext, ex) = push(c.code, ex)

function emit_pred(c::CMContext, pred_ex) 
    emit(c, :( 
        if !($pred_ex) 
            return false
        end 
    ))
end

function emit_egal_pred(c::CMContext, ex1, ex2)
    emit_pred(c, :( is_egal(($ex1), ($ex2)) ))
    ex1
end

# return symbol to which ex is assigned
emit_bind(c::CMContext, a::Atom, ex) = emit_egal_pred(c, quot(a.value), ex)
function emit_bind(c::CMContext, var::Var, ex)
    name = var.name
    if has(c.assigned_vars, var)
        emit_egal_pred(c, name, ex)
    else
        emit(c, :(
            ($name) = ($ex)
        ))
        add(c.assigned_vars, var)
    end
    name
end
