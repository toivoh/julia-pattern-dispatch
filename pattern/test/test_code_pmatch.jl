
load("pattern/req.jl")
req("pattern/core.jl")
req("pattern/composites.jl")
req("pattern/recode.jl")
load("pattern/pmatch.jl")
req("prettyshow/prettyshow.jl")

@showln @assert_fails code_pmatch(nonematch, :arg)

X = pvar(:X)

pprintln()
@pshowln code_pmatch(X, :arg)
pprintln()
@pshowln code_pmatch(1, :arg)

#pprintln(code_pmatch(DomPattern(pvar(:x), domain(Int)), :arg))

println()
@pshowln code_pmatch((1, X), :args) 
# println()
# @pshowln code_pmatch({1, X}, :args) 


function show_code_pmatch(p)
    println()
    println("pattern = ", p)

    c = PMContext()
    code_pmatch(c, aspattern(p),:x)
    println("vars = ", c.assigned_vars)
#    println("code:")
#    foreach(x->println("\t", x), c.code)
    pprintln(expr(:block, c.code))
end

#@pvar X, Xi::Int
X, Xi = pvar(:X), pvar(:Xi, Int)

show_code_pmatch(1)
show_code_pmatch(X)
show_code_pmatch(Xi)
show_code_pmatch((1,X))
show_code_pmatch((X,X))


