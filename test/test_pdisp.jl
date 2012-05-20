

load("pattern/pdispatch.jl")

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

@pattern f2({x,y}) = 1
@pattern f2(x) = 2

println()
@show f2(1)
@show f2({1})
@show f2({1,2})
@show f2((1,2))
@show f2({1,2,3})

@pattern f3((x,y)) = 1
@pattern f3(x) = 2

println()
@show f3(1)
@show f3((1))
@show f3((1,2))
@show f3({1,2})
@show f3((1,2,3))

println()
println("(g=1;@pattern g(x)=1) throws: ", @assert_fails begin
    g = 1
    @pattern g(x)=1
end)

println("(h(x)=x;@pattern h(x)=1) throws: ", @assert_fails begin
    h(x)=x
    @pattern h(x)=1
end)

