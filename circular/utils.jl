
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
