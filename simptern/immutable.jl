
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

# type ImmNew
#     d::Dict
#     typenames::Vector
# end

# function replace_new(ex::Expr, imn::ImmNew)
#     if is_expr(ex, :call) && ex.args[1] == :new
#         fname, fargs = ex.args[1], ex.args[2:end]
#         @gensym cargs key
#         quote            
#             ($cargs) = convert(($asttuple(imn.typenames)), ($asttuple(fargs)))
#             ($key) = ImmVector{Any}(($cargs)...)            
#             @setdefault ($quot(imn.d))[($key)] = ($fname)(($cargs)...)
#         end
#     else
#         expr(ex.head, {replace_new(arg, imn) for arg in ex.args})
#     end
# end
# replace_new(ex, imn::ImmNew) = ex

replace_symbol(ex::Symbol, from::Symbol, to::Symbol) = (ex == from ? to : ex)
function replace_symbol(ex::Expr, from::Symbol, to::Symbol) 
    expr(ex.head, {replace_symbol(arg, from, to) for arg in ex.args})
end
replace_symbol(ex, from::Symbol, to::Symbol) = ex


macro immutable(ex) 
    code_immutable_type(ex)
end
function code_immutable_type(ex)
    @expect is_expr(ex, :type, 2)
    typesig, defs = tuple(ex.args...)
    ts = is_expr(typesig, :comparison) ? typesig.args[1] : typesig
    typename = (is_expr(ts, :curly) ? ts.args[1] : ts)::Symbol

    @expect is_expr(defs, :block)
    
    fieldtypes = {}
    constructors = {}
    newdefs = {}
    for def in defs.args
        if is_fdef(def)
            signature, body = split_fdef(def)
            @expect is_expr(signature, :call)
            if signature.args[1] == typename  # constructor
                push(constructors, (signature, body))
                continue
            end
        end
        if isa(def, Symbol);                 push(fieldtypes, quot(Any))
        elseif is_expr(def, doublecolon, 2); push(fieldtypes, def.args[2]); end
        push(newdefs, def)
    end

    if isempty(constructors)
        constructors = {(:(($typename)(args...)), :(new(args...)))}
    end

    memodict = Dict()
#     imn = ImmNew(memodict, fieldtypes)
    @gensym immnew key cargs
    for (signature, body) in constructors
#        body = replace_new(body, imn)
        body = replace_symbol(body, :new, immnew)
        body = quote
            ($immnew)(args...) = begin
                ($cargs) = convert(($asttuple(fieldtypes)), args)
                ($key) = ImmVector{Any}(($cargs)...)            
                @setdefault ($quot(memodict))[($key)] = new(($cargs)...)
            end
            ($body)
        end
        push(newdefs, :(($signature)=($body)))
    end

    quote
        ($expr(:type, typesig, expr(:block, newdefs)))
        __immdict(::Type{$typename}) = ($quot(memodict))
    end
end
