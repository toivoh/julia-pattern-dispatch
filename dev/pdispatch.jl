
load("utils/req.jl")
req("utils/utils.jl")
req("recode.jl")
req("pmatch.jl")


function split_fdef(fdef::Expr)
    @expect (fdef.head == :function) || (fdef.head == :(=))
    @expect length(fdef.args) == 2
    signature, body = tuple(fdef.args...)
    @expect is_expr(signature, :call)
    @expect length(signature.args) >= 1
    (signature, body)
end
split_fdef(f::Any) = error("split_fdef: expected function definition, got\n$f")


# -- @patmethod ---------------------------------------------------------------

type PatternMethod
    pattern
    body

    dispfun::Function
end
function patmethod(pattern, body)
    dispfun = create_patmethod_dispfun(pattern, body)
    PatternMethod(pattern, body, dispfun)
end

function create_patmethod_dispfun(pattern, body)
    eval(code_patmethod_dispfun(pattern, body))
end
function code_patmethod_dispfun(pattern, body)
    argsname = gensym("args")
    pmc=PMContext(:(false,nothing))
    code_pmatch(pmc, pattern,argsname)
    push(pmc.code, :(true, ($body)))

    :( (($argsname)...)->(begin
        ($pmc.code...)        
    end))
end


macro patmethod(fdef)
    code_patmethod(fdef)
end
function code_patmethod(fdef)
    signature, body = split_fdef(fdef)
    @expect is_expr(signature, :call)
    pattern_ex = quotedtuple(signature.args[2:end])

    pattern_ex = recode_pattern_ex(pattern_ex)

    # evaluates the pattern expression inline
    :( patmethod(($pattern_ex), ($quotevalue(body))) )
end
