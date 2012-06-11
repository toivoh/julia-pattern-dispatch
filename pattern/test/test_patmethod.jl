
load("pattern/req.jl")
req("pattern/dispatch.jl")
req("pattern/test/utils.jl")

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
