
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


function show_code_pmatch(p,vars::PVar...)
    println()
    println("pattern = ", p)

    c = PMContext()
    code_pmatch(c, p,:x)
    println("vars = ", c.assigned_vars)
#    println("code:")
#    foreach(x->println("\t", x), c.code)
    pprintln(expr(:block, c.code))
end

#@pvar X, Xi::Int
X = pvar(:X)

show_code_pmatch(1)
show_code_pmatch(X, X)
#show_code_pmatch(Xi, Xi)
show_code_pmatch((1,X), X)
show_code_pmatch((X,X), X)


