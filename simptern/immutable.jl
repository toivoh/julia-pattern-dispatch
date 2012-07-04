
require("simptern/utils.jl")
require("simptern/staged.jl")


# -- egal ---------------------------------------------------------------------
egal(x) = true
egal(x,y,z,args...) = egal(x,y) && egal(y,z,args...)

egal(x,y) = is(x,y)
egal{T<:Number}(x::T, y::T) = isequal(x, y)
egal{T<:Tuple}(xs::T, ys::T) = all({egal(x,y) for (x,y) in zip(xs,ys)})


# -- ImmArray -----------------------------------------------------------------
type ImmArray{T,N} <: AbstractArray
    data::Array{T,N}

    ImmArray(x::AbstractArray{T,N}) = new(copy(x))
    ImmArray{S}(x::AbstractArray{S,N}) = new(convert(Array{T,N},x))
    ImmArray(args...) = (@assert N==1; new(T[args...]))
end
ImmArray{T,N}(x::Array{T,N}) = ImmArray{T,N}(x)

typealias ImmVector{T} ImmArray{T,1}
immvec{T}(args::T...) = ImmVector{T}(args...)

ndims{T,N}(x::ImmArray{T,N}) = N
eltype{T,N}(x::ImmArray{T,N}) = T
size(x::ImmArray) = size(x.data)
numel(x::ImmArray) = numel(x.data)
ref(x::ImmArray, inds...) = ref(x.data, inds...)

show(io::IO, x::ImmArray) = print(io, typeof(x), "(", x.data, ")")

function egal(xs::ImmArray, ys::ImmArray)
    (size(xs)==size(ys)) && all(map(egal, xs.data,ys.data))
end
isequal(x::ImmArray, y::ImmArray) = egal(x, y)
hash(x::ImmArray) = hash(x.data)


# -- @immutable ---------------------------------------------------------------

function immcanon{T}(x::T)
    key = ImmVector{Any}(get_all_fields(x)...)
    memo = get_immdict(x)
    @setdefault memo[key] = x
end

@staged function get_all_fields(x)
    expr(:tuple, { :(x.($quot(name))) for name in x.names })
end
@staged function get_immdict(x)
    quot(Dict{ImmVector,x}())
end

function replace_new(ex::Expr)
    ex = expr(ex.head, {replace_new(arg) for arg in ex.args})
    if is_expr(ex, :call) && ex.args[1] == :new
        expr(:call, quot(immcanon), ex)
    else
        ex
    end
end
replace_new(ex) = ex

macro immutable(ex) 
    code_immutable_type(ex)
end
function code_immutable_type(ex)
    @expect is_expr(ex, :type, 2)
    typesig, defs = tuple(ex.args...)
    ts = is_expr(typesig, :comparison) ? typesig.args[1] : typesig
    typename = (is_expr(ts, :curly) ? ts.args[1] : ts)::Symbol

    @expect is_expr(defs, :block)

    fielddefs, newdefs = {}, {}
    needs_default_constructor = true
    for def in defs.args
        if is_fdef(def)
            signature, body = split_fdef(def)
            @expect is_expr(signature, :call)
            if signature.args[1] == typename  # constructor
                needs_default_constructor
                body = replace_new(body)
                def = :(($signature)=($body))
            end
        elseif isa(def, Symbol) || is_expr(def, doublecolon, 2)
            push(fielddefs, def)
        end

        push(newdefs, def)
    end

    if needs_default_constructor
        push(newdefs, :(
            ($typename)($fielddefs...) = ($quot(immcanon))(new($fielddefs...))
        ))
    end

    expr(:type, typesig, expr(:block, newdefs))
end
