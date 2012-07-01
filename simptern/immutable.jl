

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
