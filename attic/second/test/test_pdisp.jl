
load("utils/req.jl")
load("pdispatch.jl")

mtable = PatternMethodTable(:f)
add(mtable, (@patmethod f(1) = 42))
add(mtable, (@patmethod f(x) = x))

f = (args...)->(dispatch(mtable, args))

println()
@show f(0)
@show f(1)
@show f(2)
@show f(3)

@pattern ff(x) = x
@pattern ff(1) = 42

println()
@show ff(0)
@show ff(1)
@show ff(2)
@show ff(3)


println("(g=1;@pattern g(x)=1) throws: ", @assert_fails begin
    g = 1
    @pattern g(x)=1
end)

println("(h(x)=x;@pattern h(x)=1) throws: ", @assert_fails begin
    h(x)=x
    @pattern h(x)=1
end)

