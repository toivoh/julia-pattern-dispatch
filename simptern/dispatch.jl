
require("simptern/pattern.jl")


# -- @patmethod ---------------------------------------------------------------

type PatternMethod
    signature::Pattern
    body

    dispfun::Function
end
patmethod(rawsig, body) = patmethod(pattern(rawsig), body)
function patmethod(signature::Pattern, body)
    dispfun = create_patmethod_dispfun(signature, body)
    PatternMethod(signature, body, dispfun)
end

function create_patmethod_dispfun(signature::Pattern, body)
    eval(code_patmethod_dispfun(signature, body))
end
function code_patmethod_dispfun(signature::Pattern, body)   
#    varnames = get_symbol_names(matchnode)
    argname = get_argname(signature)
    code = code_match(signature, :(false,nothing))
    :( (($argname)...)->(begin
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
