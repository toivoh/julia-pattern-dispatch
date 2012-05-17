
load("utils/req.jl")
load("pmatch.jl")
req("utils/utils.jl")
req("../prettyshow/prettyshow.jl")

@showln @assert_fails code_pmatch(nonematch, :arg)

X = pvar(:X)

pprintln()
@pshowln code_pmatch(X, :arg)
pprintln()
@pshowln code_pmatch(1, :arg)

#pprintln(code_pmatch(DomPattern(pvar(:x), domain(Int)), :arg))

println()
@pshowln code_pmatch((1, X), :args) 
println()
@pshowln code_pmatch({1, X}, :args) 