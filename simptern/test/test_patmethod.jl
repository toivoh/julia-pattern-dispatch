
require("simptern/dispatch.jl")

m1 = (@patmethod f(1) = 42)
m2 = (@patmethod f(x) =  x)

for x=0:5
    r1 = m1.dispfun(x)
    r2 = m2.dispfun(x)
    if x==1
        @test r1 == (true, 42)
    else
        @test r1 == (false, nothing)
    end
    @test r2 == (true, x)
end

# mt = PatternMethodTable(:f)
# add(mt, m1)
# add(mt, m2)

# @test {dispatch(mt,(x,)) for x=0:4} == {0,42,2,3,4}
