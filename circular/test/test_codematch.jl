
load("pattern/req.jl")
req("circular/recode.jl")
req("circular/test/utils.jl")


function test_code_match(p::Pattern)
    ex = code_match(p, :value)
    print_sig("code_match(", p, ", :value) =")
    println(indent("\n",ex))
    println()
end

test_code_match(@pattern 1)
test_code_match(@pattern x)
test_code_match(@pattern (1, x))
test_code_match(@pattern (x, x))
test_code_match(@pattern x~(x,))
test_code_match(@pattern x~(y, (5, z)))
