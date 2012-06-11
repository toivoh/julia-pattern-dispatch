

load("pattern/req.jl")
req("pattern/recode.jl")

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
    signature::PNode
    body

    dispfun::Function
end
function patmethod(signature::PNode, body)
    dispfun = create_patmethod_dispfun(signature, body)
    PatternMethod(signature, body, dispfun)
end

function create_patmethod_dispfun(signature::PNode, body)
    eval(code_patmethod_dispfun(signature, body))
end
function code_patmethod_dispfun(signature::PNode, body)
    argsname = gensym("args")
    vars, code = code_match(signature,argsname, :(false,nothing))

    :( (($argsname)...)->(begin
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


