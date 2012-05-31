
macro expect(pred)
    quote
        ($pred) ? nothing : error("expected: ", ($string(pred))", == true")
    end
end


## -- PrIO --------------------------------------------------------------------

abstract PrIO <: IO

print(io::PrIO, c::Char) = print_char(io, c)
for S in [:ASCIIString, :UTF8String, :RopeString, :String]
    @eval print(io::PrIO, s::($S)) = print_str(io, s)
end
show(io::PrIO, s::Symbol) = print(io, string(s))


print_str(io::PrIO, s::String) = (for c in s; print_char(io, c); end)


pprint(io::IO, args...) = print(pretty(io), args...)
pprint(args...) = pprint(OUTPUT_STREAM, args...)


function show(io, x) 
    if isa(io, PrIO)
        print(io, sshow(x))
    elseif isa(io, IO)
        ccall(:jl_show_any, Void, (Any, Any,), io, x)
    else
        error("unimplemented!")
    end
end


## -- PrettyTerm --------------------------------------------------------------

type PrettyTerm <: PrIO
    sink::IO
    width::Int
    xpos::Int

    function PrettyTerm(sink::IO, width::Int)
        @expect width > 0
        new(sink, width, 0)
    end
end

function print_char(io::PrettyTerm, c::Char)
    if c=='\t'    # tab
        for k=1:((-io.xpos)&7)
            print(io.sink, ' ')
            io.xpos += 1
        end
    else
        print(io.sink, c)
        io.xpos += 1
        if c == '\n'
            io.xpos = 0
        end
    end
end


## -- PrettyStream ------------------------------------------------------------

type PrettyStream <: PrIO
    parent::PrettyTerm
    indent::Int
    wrap::Bool

    PrettyStream(parent::PrettyTerm, indent::Int) = new(parent, indent, false)
end

pretty(io::PrIO) = io
pretty(io::PrettyTerm) = PrettyStream(io, 0)
pretty(io::IO) = pretty(PrettyTerm(io, 80))

indented(io::PrettyStream) = PrettyStream(io.parent, io.indent+4)
indented(io::IO) = indented(pretty(io))

function print_char(io::PrettyStream, c::Char)
    if io.wrap && (io.parent.xpos >= io.parent.width)  # wrap
        print_char(io.parent, '\n') 
    end  
    if (io.parent.xpos == 0) && (io.indent > 0)        # indent
        for k=1:io.indent; print(io.parent, ' '); end
        io.wrap = (2*io.parent.xpos >= io.parent.width)
    end
    print(io.parent, c)
end

function print_str(io::PrettyStream, s::String)
    n = strlen(s)  # todo: only count chars up to first newline
    if (io.indent+n <= io.parent.width < io.parent.xpos+n)  
        pprint(io, '\n')  # wrap string to next line
    end
    for c in s; pprint(io, c); end
end


# -- Indent -------------------------------------------------------------------

type PNest
    f::Function
end
print(io::IO, nest::PNest) = nest.f(io)

indent(args...) = PNest(io->print(indented(io), args...))

delim_list(args, pre, post) = PNest(io->(begin
        n=length(args)
        for k=1:n
            print(io, pre)
            print(io, args[k])
            if k < n; print(io, post); end
        end
    end
))

# type Indent
#     args::Tuple
# end
# indent(args...) = Indent(args)

# print(io::IO, ind::Indent) = print(indented(io), ind.args...)


