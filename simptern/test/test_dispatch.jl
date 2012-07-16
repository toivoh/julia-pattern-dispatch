
require("simptern/dispatch.jl")

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

@pattern f3(atom(nothing)) = 1
@pattern f3(x) = 2

@test is(f3(nothing),1)
@test is(f3(1),2)
@test is(f3(:x),2)
@test is(f3("hello"),2)
