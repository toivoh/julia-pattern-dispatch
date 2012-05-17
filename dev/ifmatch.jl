
load("utils/req.jl")
req("utils/utils.jl")
req("recode.jl")
req("pmatch.jl")

macro ifmatch(ex)
    code_ifmatch_let(ex)
end
function code_ifmatch_let(ex)
    @expect is_expr(ex, :let)
    body = ex.args[1]
    #matches = ex.args[2:end]
    @expect length(ex.args) == 2
    match = ex.args[2]

    @expect is_expr(match, :(=), 2)

    pattern, valex = match.args[1], match.args[2]
    code_ifmatch_let(pattern, valex, body)
end

function code_ifmatch_let(pattern_ex, value_ex, body)
    value_name = gensym("value")
    
    pattern_ex = recode_pattern_ex(pattern_ex)
    pattern = eval(pattern_ex)

    pmc = PMContext()
    code_pmatch(pmc, pattern,value_name)

    varnames = get_varnames(pmc)
    :(
        let ($value_name)=($value_ex)
            local ($varnames)
            let
                ($pmc.code...)
                ($body)
                true
            end
        end
    )
end
