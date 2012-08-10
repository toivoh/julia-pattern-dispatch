
const doublecolon = symbol("::")

quot(ex) = expr(:quote, ex)

macro expect(pred)
    quote
        ($pred) ? nothing : error("expected: ", ($string(pred))", == true")
    end
end


macro show(ex)
    :(println(($string(ex)), "\t= ", repr($ex)) )
end
macro showln(ex)
    :(println(($string(ex)), "\n\t=", repr($ex)) )
end

macro test(ex)
    quote
        @assert ($ex)
    end
end
