
load("pattern/req.jl")
req("pattern/dispatch.jl")
req("pattern/test/utils.jl")

@pattern f(1) = 42
@pattern f(x) =  x

@show {f(x) for x=0:4}
