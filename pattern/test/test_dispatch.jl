
load("pattern/req.jl")
req("pattern/dispatch.jl")
req("pattern/test/utils.jl")

@pattern f(1) = 42
@pattern f(x) =  x

@test {f(x) for x=0:4}=={0,42,2,3,4}


@pattern f2((x,y)) = x*y
@pattern f2(x) = nothing

@test f2((2,5)) == 10
@test f2((4,3)) == 12
@test is(nothing, f2(1) )
@test is(nothing, f2("hello") )
@test is(nothing, f2((1,)) )
@test is(nothing, f2((1,2,3)) )


println("\n# Repeated arguments are allowed:") 
@pattern eq(x,x) = true
@pattern eq(x,y) = false

@show eq(1,1)
@show eq(1,2)
