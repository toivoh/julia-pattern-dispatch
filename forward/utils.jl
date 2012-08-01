
quot(value) = expr(:quote, value)

is_expr(ex, head::Symbol) = (isa(ex, Expr) && (ex.head == head))
function is_expr(ex, head::Symbol, nargs::Int)
    is_expr(ex, head) && length(ex.args) == nargs
end

macro expect(pred)
    quote
        ($pred) ? nothing : error("expected: ", ($string(pred))", == true")
    end
end

macro unimplemented(signature)
    @expect is_expr(signature, :call)
    quote
        ($signature) = error("Unimplemented! Todo: print arg types")
    end
end

# macro setdefault(args...)
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
