
load("pattern/req.jl")
req("circular/utils.jl")

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

macro pshow(ex)
    :(pprintln(($string(ex)), "\t= ", ($ex)) )
end
macro pshowln(ex)
    :(pprintln(($string(ex)), "\n\t=", ($ex)) )
end

# todo: pull these two together!
macro psymshow(call)
    @expect is_expr(call, :call)
    args = call.args
    @expect length(args)==3
    op, x, y = tuple(args...)
    quote
        pprint($string(call))
        pprint("\t= ",    ($call))
        pprintln(",\tsym = ", ($op)($y,$x))
    end
end
macro psymshowln(call)
    @expect is_expr(call, :call)
    args = call.args
    @expect length(args)==3
    op, x, y = tuple(args...)
    quote
        pprintln($string(call))
        pprintln("\t= ",    ($call))
        pprintln("sym\t= ", ($op)($y,$x))
    end
end
