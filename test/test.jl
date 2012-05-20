load("pattern/pdispatch.jl")
load("pattern/ifmatch.jl")

println("# Signatures can contain a mixture of variables and literals:")
@pattern f(x) =  x
@pattern f(2) = 42

@show {f(x) for x=1:4}

println("\n# Signatures can also contain patterns of tuples and vectors:") 
@pattern f2({x,y}) = 1
@pattern f2(x) = 2

@show f2({1,2})
@show f2({"a",:x})
println()
@show f2(1)
@show f2("hello")
@show f2({1})
@show f2({1,2,3})

println("\n# Repeated arguments are allowed:") 
@pattern eq(x,x) = true
@pattern eq(x,y) = false

@show eq(1,1)
@show eq(1,2)

println("\n# staticvalue(ex) evaluates an expression at the point of definition:")
@pattern f3(staticvalue(nothing)) = 1
@pattern f3(x) = 2

@show f3(nothing)
println()
@show f3(1)
@show f3(:x)
@show f3("hello")

println("\n# A warning is printed if a new definition makes dispatch ambiguous:")
@pattern ambiguous((x,y),z) = 2
@pattern ambiguous(x,(1,z)) = 3

println("\n# Signatures are evaluated at the point of method definition:")
opnode(op, arg1, arg2) = {:call, op, arg1, arg2}

@pattern undot(opnode(:.+, arg1, arg2)) = opnode(:+, undot(arg1), undot(arg2))
@pattern undot(opnode(:.*, arg1, arg2)) = opnode(:*, undot(arg1), undot(arg2))
@pattern undot(opnode( op, arg1, arg2)) = opnode(op, undot(arg1), undot(arg2))
@pattern undot(n) = n

@show undot(opnode(:.+, :x,:y))
@show undot(opnode(:.*, :x,:y))
@show undot(opnode(:.+, :x,opnode(:.*,:y,:z)))
@show undot(opnode(:-,  :x,opnode(:.*,:y,:z)))

println("\n# No ambiguity warning, since no finite pattern matches both:")
@pattern fn(x,{1,x}) = 1
@pattern fn(x,x)     = 2

@show fn(2,{1,2})
@show fn({2,:x},{1,{2,:x}})
println()
@show fn(2,2)
@show fn({2,:x},{2,:x})

println("\n# @ifmatch let syntax:")
for k=1:4
    print("k = $k: ")
    m::Bool = @ifmatch let {x,2}={k,k}
        println("x = $x")
    end
    if !m
        println("no match")
    end
end