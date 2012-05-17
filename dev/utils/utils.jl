
const doublecolon = @eval (:(::Int)).head

quotevalue(val)     = expr(:quote, val)

macro expect(pred)
    quote
        ($pred) ? nothing : error("expected: ($string(pred)) == true")
    end
end

macro assert_fails(ex)
    @gensym err
    quote
        ($err) = nothing
        try
            ($ex)
            error("should fail, but didn't: ", ($quotevalue(ex)) )
        catch err
            ($err) = err
        end
        ($err)
    end
end


macro pshow(ex)
    :(pprintln(($string(ex)), "\t= ", ($ex)) )
end
macro pshowln(ex)
    :(pprintln(($string(ex)), " =\n", ($ex)) )
end

macro show(ex)
    :(println(($string(ex)), "\t= ", sshow($ex)) )
end
macro showln(ex)
    :(println(($string(ex)), "\n\t=", sshow($ex)) )
end

# todo: pull these two together!
macro symshow(call)
    @expect is_expr(call, :call)
    args = call.args
    @expect length(args)==3
    op, x, y = tuple(args...)
    quote
        print($string(call))
        print("\t= ",    ($call))
        println(",\tsym = ", ($op)($y,$x))
    end
end
macro symshowln(call)
    @expect is_expr(call, :call)
    args = call.args
    @expect length(args)==3
    op, x, y = tuple(args...)
    quote
        println($string(call))
        println("\t= ",    ($call))
        println("sym\t= ", ($op)($y,$x))
    end
end
