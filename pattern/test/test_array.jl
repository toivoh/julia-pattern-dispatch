
load("pattern/req.jl")
req("pattern/pattern.jl")

X = pvar(:X)

@show aspattern({})
@show aspattern([])
@show aspattern({1})
@show aspattern([1])
@show aspattern({1,2,5})
@show aspattern({1 2;3 4})
@show aspattern({1 2;3 X})

println()
@show aspattern({1}) == aspattern({1})
@show aspattern({1}) == aspattern({2})
