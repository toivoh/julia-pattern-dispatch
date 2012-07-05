
require("simptern/recode.jl")
require("simptern/code_match.jl")

macro ifmatch(ex)
    code_ifmatch_let(ex)
end
function code_ifmatch_let(ex)
    @expect is_expr(ex, :let)
    body = ex.args[1]
    # todo: allow multiple let arguments
    #matches = ex.args[2:end]
    @expect length(ex.args) == 2
    match = ex.args[2]

    @expect is_expr(match, :(=), 2)
    pattern, arg_ex = match.args[1], match.args[2]
    code_ifmatch_let(pattern, arg_ex, body)
end

function code_ifmatch_let(pattern_ex, arg_ex, body)
    arg_name = gensym("arg")
    
    pattern_ex = recode_patex(pattern_ex)
    pattern = eval(pattern_ex)

    matchnode = make_net(pattern, VarNode(arg_name))
    varnames = get_symbol_names(matchnode)
    code = code_match(matchnode)
    :(
        let ($arg_name)=($arg_ex)
            local ($varnames...)
            let
                ($code)
                ($body)
                true
            end
        end
    )
end
