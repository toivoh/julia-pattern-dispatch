
const doublecolon = symbol("::")

quot(ex) = expr(:quote, ex)
#quotuple(exprs) = expr(:tuple, {quot(ex) for ex in exprs})
asttuple(exprs) = expr(:tuple, exprs...)

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

macro setdefault(ex)
    @expect is_expr(ex, :(=))
    ref_ex, default_ex = tuple(ex.args...)
    @expect is_expr(ref_ex, :ref)
    dict_ex, key_ex = tuple(ref_ex.args...)
    @gensym dict key #defval
    quote
        ($dict)::Associative = ($dict_ex)
        ($key) = ($key_ex)
        if has(($dict), ($key))
            ($dict)[($key)]
        else
            ($dict)[($key)] = ($default_ex) # returns the newly inserted value
        end
    end
end

macro show(ex)
    :(println(($string(ex)), "\t= ", sshow($ex)) )
end
macro showln(ex)
    :(println(($string(ex)), "\n\t=", sshow($ex)) )
end
