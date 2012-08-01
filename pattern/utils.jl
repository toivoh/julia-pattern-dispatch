
macro show(ex)
    :(println(($string(ex)), "\t= ", sshow($ex)) )
end
macro showln(ex)
    :(println(($string(ex)), "\n\t=", sshow($ex)) )
end

macro test(ex)
    quote
        @assert ($ex)
    end
end
