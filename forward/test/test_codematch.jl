
load("pattern/req.jl")
req("pattern/recode.jl")
req("pattern/test/utils.jl")


function test_code_match(p::Pattern)
    vars, ex = code_match(p, :value)
    print_sig("code_match(", p, ", :value)")
    println(indent("\nvars = ",vars, "\ncode = ",ex))
    println()
end

test_code_match(@qpat 1)
test_code_match(@qpat x)
test_code_match(@qpat (1, x))
test_code_match(@qpat (x, x))
test_code_match(@qpat x~(x,))
test_code_match(@qpat x~(y, (5, z)))
