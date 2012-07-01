
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

macro memoized(ex, d)
    @expect is_expr(ex, :call)
    fname = ex.args[1]
    fargs = ex.args[2:end]
    @gensym key
    quote
        ($key) = ImmVector{Any}(($fargs...))
        has(($d),($key)) ? ($d)[($key)] : (($d)[($key)] = ($fname)($fargs...))
    end
end


function replace_new(ex::Expr, dsym::Symbol)
    if is_expr(ex, :call) && ex.args[1] == :new
#         :( memoized_apply(($quot(d)), new, ($ex.args[2:end]...)) )
        :(@memoized ($ex) ($dsym))
    else
        expr(ex.head, {replace_new(arg, dsym) for arg in ex.args})
    end
end
replace_new(ex, dsym::Symbol) = ex

# replace_symbol(ex::Symbol, from::Symbol, to::Symbol) = (ex == from ? to : ex)
# function replace_symbol(ex::Expr, from::Symbol, to::Symbol) 
#     expr(ex.head, {replace_symbol(arg, from, to) for arg in ex.args})
# end
# replace_symbol(ex, from::Symbol, to::Symbol) = ex

macro immutable(ex) 
    code_immutable_type(ex)
end
function code_immutable_type(ex)
    @expect is_expr(ex, :type, 2)
    typename, defs = tuple(ex.args...)

    @expect is_expr(defs, :block)
    
    @gensym newimm
#     fieldnames = {}
    newdefs = {}
    memodict = Dict()
    @gensym memosym
    @eval ($memosym) = ($quot(memodict))
    for def in defs.args
#         if isa(def, Symbol); push(fieldnames, def);
#         elseif is_expr(def, doublecolon, 2); push(fieldnames, def.args[1]);
        if is_fdef(def)
            signature, body = split_fdef(def)
            @expect is_expr(signature, :call)
            if signature.args[1] == typename  # constructor
                @expect is_expr(body, :block)
#                 body = quote
# #                     let new = (args...)->memoized_apply(($quot(memodict)), 
# #                                                         new, args...)
#                     let new = 5  
#                         ($body.args...)
#                     end
#                 end
                body = replace_new(body, memosym)
                def = :(($signature)=($body))
            end
        elseif is_expr(def, :line) || isa(def, LineNumberNode) # ignore line nr
        elseif isa(def, Symbol) || is_expr(def, doublecolon) # ignore fields
        else
#            error("@immutable type: unexpected def.head = ", def.head,
#                  ", def = ", def)
            error("@immutable type: def = ", def)
        end
        push(newdefs, def)
    end

    typedef = expr(:type, typename, expr(:block, newdefs))
    
    quote
        ($typedef)
        __immdict(::Type{$typename}) = ($quot(memodict))
    end
end
