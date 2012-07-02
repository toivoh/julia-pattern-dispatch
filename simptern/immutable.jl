
require("simptern/utils.jl")


# -- egal ---------------------------------------------------------------------
egal(x) = true
egal(x,y,z,args...) = egal(x,y) && egal(y,z,args...)

egal(x,y) = is(x,y)
egal{T<:Number}(x::T, y::T) = isequal(x, y)
egal{T<:Tuple}(xs::T, ys::T) = all({egal(x,y) for (x,y) in zip(xs,ys)})


# -- ImmArray -----------------------------------------------------------------
type ImmArray{T,N}
    data::Array{T,N}

    ImmArray(x::AbstractArray{T,N}) = new(copy(x))
    ImmArray{S}(x::AbstractArray{S,N}) = new(convert(Array{T,N},x))
    ImmArray(args...) = (@assert N==1; new(T[args...]))
end
ImmArray{T,N}(x::Array{T,N}) = ImmArray{T,N}(x)

typealias ImmVector{T} ImmArray{T,1}
immvec{T}(args::T...) = ImmVector{T}(args...)

ndim{T,N}(x::ImmArray{T,N}) = N
eltype{T,N}(x::ImmArray{T,N}) = T
size(x::ImmArray) = size(x.data)

function egal(xs::ImmArray, ys::ImmArray)
    (size(xs)==size(ys)) && all(map(egal, xs.data,ys.data))
end
isequal(x::ImmArray, y::ImmArray) = egal(x, y)
hash(x::ImmArray) = hash(x.data)


# -- @immutable ---------------------------------------------------------------

function memoized_apply(d::Dict, f::Function, args...)
    key = ImmVector{Any}(f, args...)
    has(d, key) ? d[key] : (d[key] = f(args...))
end

type ImmNew
    d::Dict
    typenames::Vector
end

function replace_new(ex::Expr, imn::ImmNew)
    if is_expr(ex, :call) && ex.args[1] == :new
        fname = ex.args[1]
        fargs = ex.args[2:end]        
        @gensym cargs key
        quote            
#             ($key) = ImmVector{Any}(($fargs...))
            ($cargs) = convert(($asttuple(imn.typenames)), ($asttuple(fargs)))
            ($key) = ImmVector{Any}(($cargs)...)            
#             @setdefault ($quot(imn.d))[($key)] = ($fname)($fargs...)
            @setdefault ($quot(imn.d))[($key)] = ($fname)(($cargs)...)
        end
    else
        expr(ex.head, {replace_new(arg, imn) for arg in ex.args})
    end
end
replace_new(ex, imn::ImmNew) = ex

macro immutable(ex) 
    code_immutable_type(ex)
end
function code_immutable_type(ex)
    @expect is_expr(ex, :type, 2)
    typename, defs = tuple(ex.args...)

    @expect is_expr(defs, :block)
    
    @gensym newimm
    fieldtypes = {}
    constructors = {}
    newdefs = {}
    for def in defs.args
        if is_fdef(def)
            signature, body = split_fdef(def)
            @expect is_expr(signature, :call)
            if signature.args[1] == typename  # constructor
                @expect is_expr(body, :block)
                push(constructors, (signature, body))
                continue
            end
        end
        if isa(def, Symbol); push(fieldtypes, quot(Any))
        elseif is_expr(def, doublecolon, 2); push(fieldtypes, def.args[2])
        elseif is_expr(def, :line) || isa(def, LineNumberNode) # ignore line nr
        elseif isa(def, Symbol) || is_expr(def, doublecolon) # ignore fields
        else
            error("@immutable type: def = ", def)
        end
        push(newdefs, def)
    end

    memodict = Dict()
    imn = ImmNew(memodict, fieldtypes)
    for (signature, body) in constructors
        body = replace_new(body, imn)
        push(newdefs, :(($signature)=($body)))
    end

    typedef = expr(:type, typename, expr(:block, newdefs))
    
    quote
        ($typedef)
        __immdict(::Type{$typename}) = ($quot(memodict))
    end
end
