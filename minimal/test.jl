
require("pattern.jl")

show(io, x) = isa(io,IOStream) ? ccall(:jl_show_any, Void, (Any,Any,), io, x) :
              print(io, repr(x))


# list in patterns order of priority:
@pattern begin
    f(1)      = 42
    f(::Int)  = 5
#    f(x)      = x
end

# patterns = quote
#     f(1)          = 42
#     f(x::Integer) =  x^2
#     f(::Number)   =  5
#     f(x)          =  x
# end

# code_pattern(patterns)
