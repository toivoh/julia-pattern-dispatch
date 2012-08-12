
require("pattern.jl")

show(io, x) = isa(io,IOStream) ? ccall(:jl_show_any, Void, (Any,Any,), io, x) :
              print(io, repr(x))


# list in patterns order of priority:
@pattern begin
    f(1)       = 42
    f(::Int)   = 5
    f((x,y))   = x*y
    f(x~{x,y}) = y
    f({x,y})   = (x, y)
    f(x)       = x
    f(x,x)     = x
    f(x,y)     = x+y
end

@test f(1) === 42
@test f(2) === 5
@test f((6,5)) === 30
r={1,9}; r[1] = r
@test f(r) === 9 
@test f({1,2}) === (1,2)
@test f(2.5) === 2.5
@test f(4,4) === 4
@test f(3,4) === 7

# patterns = quote
#     f(1)          = 42
#     f(x::Integer) =  x^2
#     f(::Number)   =  5
#     f(x)          =  x
# end

# code_pattern(patterns)
