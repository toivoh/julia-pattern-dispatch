
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
abstract   ObjectPattern <: Pattern
abstract     SetPattern <: ObjectPattern
abstract     NamedPattern <: ObjectPattern
abstract       IdPattern <: NamedPattern

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


# Collected (index, Pattern) pairs for index properties
type IndexPattern{K} <: Pattern
    factors::Dict{K,ObjectPattern}

    IndexPattern(factors::Dict) = new(convert(Dict{K,ObjectPattern}, factors))
end

function code_match(c, ps::IndexPattern,prop)
    for (key, p) in ps.factors;  code_match(c, p,code_get(c,prop, key));  end
end


type TypePattern <: SetPattern
    T::Union(Type, Tuple)
end
code_match(c, p::TypePattern,ex) = emit_pred(c,:( isa(($ex),($quot(p.T))) ))


type ProductPattern <: SetPattern
    factors::Dict{AspectKey, Pattern}
end

function code_match(c, pp::ProductPattern,sym::Symbol)
    for p in pp.factors;  code_match(c, pp,sym);  end
end

function show(io::IO, p::ProductPattern) 
    pprint(io, enclose("ProductPattern(", p.factors, ")"))
end


type NamedProduct <: NamedPattern
    id::IdPattern
    prod::ProductPattern
end
get_label(p::NamedProduct) = p.id

function code_match(c, p::NamedProduct,ex)
    sym = code_match(c, p.id,ex)
    code_match(c, p.prod,sym)
end

type PVar <: IdPattern
    name::Symbol
end
show(io::IO, var::PVar) = print(io, "PVar(:", var.name, ")")
type Atom{T} <: IdPattern
    value::T
end

get_label(p::IdPattern) = p

# returns symbol that gets bound to ex
code_match(c, p::IdPattern,ex) = emit_bind(c, p,ex)


#code_match(c, p::KeyPattern,ex) = code_match(c, p.p,code_get(c,p.key, ex))
# function show(io::IO, p::KeyPattern)
#     pprint(io, "KeyPattern(", indent(p.key.name, ", ", p.p), ")")
# end






# -- Aspects ------------------------------------------------------------------


code_get(c,key::AspectKey, ex) = code_get(c,key.aspect, ex)


type SelfAspect{T} <: Aspect{T}; end
code_get(c,::SelfAspect, ex) = ex

#abstract Property{T} <: Aspect{T}
#abstract   IndexProperty{K} <: Property{IndexPattern{K}}
abstract IndexProperty{K} <: Aspect{IndexPattern{K}}

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

type_asp  = AspectKey(:type_asp,  SelfAspect{TypePattern}(), {})

func_asp  = AspectKey(:func_asp,  FuncProperty(),  {type_asp})
field_asp = AspectKey(:field_asp, FieldProperty(), {type_asp})
apply_asp = AspectKey(:apply_asp, ApplyProperty(), {type_asp})

ref_asp   = AspectKey(:ref_asp,   RefProperty(),   {type_asp, func_asp})



# -- Matching code generation -------------------------------------------------

type CMContext
    assigned_vars::Set{PVar}
    code::Vector
    CMContext() = new(Set{PVar}(), {})
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
function emit_bind(c::CMContext, var::PVar, ex)
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
