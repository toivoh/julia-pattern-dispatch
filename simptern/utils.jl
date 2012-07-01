
const doublecolon = symbol("::")

quot(ex) = expr(:quote, ex)

is_expr(ex, head::Symbol) = (isa(ex, Expr) && (ex.head == head))
function is_expr(ex, head::Symbol, nargs::Int)
    is_expr(ex, head) && length(ex.args) == nargs
end

macro expect(pred)
    quote
        ($pred) ? nothing : error("expected: ", ($string(pred))", == true")
    end
end

function is_fdef(ex::Expr) 
    is_expr(ex, :function, 2) || 
    (is_expr(ex, :(=), 2) && is_expr(ex.args[1], :call))
end
is_fdef(ex) = false

function split_fdef(fdef::Expr)
    @expect (fdef.head == :function) || (fdef.head == :(=))
    @expect length(fdef.args) == 2
    signature, body = tuple(fdef.args...)
    @expect is_expr(signature, :call)
    @expect length(signature.args) >= 1
    (signature, body)
end
split_fdef(f::Any) = error("split_fdef: expected function definition, got\n$f")

macro show(ex)
    :(println(($string(ex)), "\t= ", sshow($ex)) )
end
macro showln(ex)
    :(println(($string(ex)), "\n\t=", sshow($ex)) )
end
