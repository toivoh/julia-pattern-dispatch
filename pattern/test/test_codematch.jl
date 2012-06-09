
load("pattern/req.jl")
req("pattern/recode.jl")
req("pattern/test/utils.jl")


function test_code_match(p::Pattern)
    vars, ex = code_match(p, :value)
    print_sig("code_match(", p, ", :value)")
    println(indent("\nvars = ",vars, "\ncode = ",ex))
    println()
end

test_code_match(@pattern 1)
test_code_match(@pattern x)
test_code_match(@pattern (1, x))
test_code_match(@pattern (x, x))
test_code_match(@pattern x~(x,))
test_code_match(@pattern x~(y, (5, z)))
