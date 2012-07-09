
require("simptern/pnode.jl")
require("simptern/unify.jl")
require("simptern/recode.jl")
require("simptern/code_match.jl")


# -- @patmethod ---------------------------------------------------------------

const __patmethod_arg = gensym("arg")

type PatternMethod
    signature::MatchNode
    body

    dispfun::Function
end
function patmethod(sigpattern::Pattern, body)
    signature = make_net(sigpattern, VarNode(__patmethod_arg))
    dispfun = create_patmethod_dispfun(signature, body)
    PatternMethod(signature, body, dispfun)
end

function create_patmethod_dispfun(signature::MatchNode, body)
    eval(code_patmethod_dispfun(signature, body))
end
function code_patmethod_dispfun(signature::MatchNode, body)   
#    varnames = get_symbol_names(matchnode)
    code = code_match(signature, :(false,nothing))
    :( (($__patmethod_arg)...)->(begin
        ($code)
        (true, ($body))
    end))
end


macro patmethod(fdef)
    code_patmethod(fdef)
end
function code_patmethod(fdef)
    fsig, body = split_fdef(fdef)
    @expect is_expr(fsig, :call)

    signature_ex = expr(:tuple, fsig.args[2:end])
    signature_ex = recode_patex(signature_ex)

    # evaluates the signature expression inline
    :( patmethod(($signature_ex), ($quot(body))) )
end
