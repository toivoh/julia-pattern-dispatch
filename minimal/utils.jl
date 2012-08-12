
macro expect(pred)
    quote
        ($esc(pred)) ? nothing : 
        error("expected: ", ($string(pred))", == true")
    end
end

const doublecolon = symbol("::")

quot(ex) = expr(:quote, ex)

is_expr(ex, head::Symbol) = (isa(ex, Expr) && (ex.head == head))
is_expr(ex, head::Symbol, n::Int) = is_expr(ex, head) && length(ex.args) == n

function split_fdef(fdef::Expr)
    @expect (fdef.head == :function) || (fdef.head == :(=))
    @expect length(fdef.args) == 2
    signature, body = tuple(fdef.args...)
    @expect is_expr(signature, :call)
    @expect length(signature.args) >= 1
    (signature, body)
end
split_fdef(f::Any) = error("split_fdef: expected function definition, got\n$f")

split_fdef3(fdef) = ((s, b) = split_fdef(fdef); (s.args[1], s.args[2:end], b))

function common_value(xs)
    k = start(xs)
    @expect !done(xs, k)
    x, k = next(xs, k)
    while !done(xs, k)
        xk, k = next(xs, k)
        if !(xk === x) error("common_value: !($x === $xk)") end
    end
    x
end


macro show(ex)
    :(println(($string(ex)), "\t= ", repr($esc(ex))) )
end
macro showln(ex)
    :(println(($string(ex)), "\n\t=", repr($esc(ex))) )
end

macro test(ex)
    quote
        @assert ($esc(ex))
    end
end
