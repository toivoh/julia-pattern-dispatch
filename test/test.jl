load("pattern/pdispatch.jl")

@pattern f(x) =  x
@pattern f(2) = 42

@show {f(x) for x=1:4}

@pattern f2({x,y}) = 1
@pattern f2(x) = 2

println() 
@show f2({1,2})
@show f2({"a",:x})
println()
@show f2(1)
@show f2("hello")
@show f2({1})
@show f2({1,2,3})

@pattern eq(x,x) = true
@pattern eq(x,y) = false

println()
@show eq(1,1)
@show eq(1,2)

println()
@pattern ambiguous((x,y),z) = 2
@pattern ambiguous(x,(1,z)) = 3

println()
# no ambiguity warning
@pattern f3(x,{1,x}) = 1
@pattern f3(x,x)     = 2

@show f3(2,{1,2})
@show f3({2,:x},{1,{2,:x}})
println()
@show f3(2,2)
@show f3({2,:x},{2,:x})
