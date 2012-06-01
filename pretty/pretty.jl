
macro expect(pred)
    quote
        ($pred) ? nothing : error("expected: ", ($string(pred))", == true")
    end
end


## -- PrettyIO ----------------------------------------------------------------

abstract PrettyIO <: IO

print(io::PrettyIO, c::Char) = print_char(io, c)
for S in [:ASCIIString, :UTF8String, :RopeString, :String]
    @eval print(io::PrettyIO, s::($S)) = print_str(io, s)
end
show(io::PrettyIO, s::Symbol) = print(io, string(s))


print_str(io::PrettyIO, s::String) = (for c in s; print_char(io, c); end)


pprint(io::IO, args...) = print(pretty(io), args...)
pprint(args...) = pprint(OUTPUT_STREAM, args...)

pshow(io::IO, args...) = show(pretty(io), args...)
pshow(args...) = pshow(OUTPUT_STREAM, args...)


function show(io, x) 
    if isa(io, PrettyIO)
        print(io, sshow(x))
    elseif isa(io, IO)
        ccall(:jl_show_any, Void, (Any, Any,), io, x)
    else
        error("unimplemented!")
    end
end


## -- PrettyTerm --------------------------------------------------------------

type PrettyTerm <: PrettyIO
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

type PrettyStream <: PrettyIO
    parent::PrettyTerm
    indent::Int
    wrap::Bool

    PrettyStream(parent::PrettyTerm, indent::Int) = new(parent, indent, false)
end

pretty(io::PrettyIO) = io
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
    extra_args::Tuple

    PNest(f::Function, extra_args...) = new(f, extra_args)
end
show(io::IO, nest::PNest) = nest.f(io, nest.extra_args...)
# show(io::PrettyIO, nest::PNest) = nest.f(io, nest.extra_args...)
# show(io::IO, nest::PNest) = pshow(io, nest)

# type PNest
#     f::Function
# end
# print(io::IO, nest::PNest) = nest.f(io)

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


# == Expr prettyprinting ======================================================

const doublecolon = @eval (:(x::Int)).head

## list printing
function pshow_comma_list(io::PrettyIO, args::Vector, 
                          open::String, close::String) 
    pshow_delim_list(io, args, open, ", ", close)
end
function pshow_delim_list(io::PrettyIO, args::Vector, open::String, 
                          delim::String, close::String)
    pprint(io, indent(open, 
                PNest(pshow_list_delim, args, delim)),
           close)
end
function pshow_list_delim(io::PrettyIO, args::Vector, delim::String)
    for (arg, k) in enumerate(args)
        show(io, arg)
        if k < length(args)
            pprint(io, delim)
        end
    end
end

## show the body of a :block
pshow_mainbody(io::PrettyIO, ex) = show(io, ex)
function pshow_mainbody(io::PrettyIO, ex)
    if is_expr(ex, :block)
        args = ex.args
        for (arg, k) in enumerate(args)
            if !is_expr(arg, :line)
                pprint(io, "\n")
            end
            show(io, arg)
        end
    else
        if !is_expr(ex, :line);  pprint(io, "\n");  end
        show(io, ex)
    end
end

## show arguments of a block, and then body
pshow_body(io::PrettyIO, body) = pshow_body(io, {}, body)
function pshow_body(io::PrettyIO, arg, body)
    pprint(io, indent(arg, PNest(pshow_mainbody, body) ))
end
function pshow_body(io::PrettyIO, args::Vector, body)
    pprint(io, indent(
            PNest(pshow_comma_list, args, "", ""), 
            PNest(pshow_mainbody, body)
        ))
end

## show ex as if it were quoted
function pshow_quoted_expr(io::PrettyIO, sym::Symbol)
    if !is(sym,:(:)) && !is(sym,:(==))
        pprint(io, ":$sym")
    else
        pprint(io, ":($sym)")
    end
end
function pshow_quoted_expr(io::PrettyIO, ex::Expr)
    if ex.head == :block
        pprint(io, "quote ", PNest(pshow_body, ex), "\nend")
    else
        pprint(io, "quote(", indent(ex), ")")
    end
end
pshow_quoted_expr(io::PrettyIO, ex) =pprint(io, ":($ex)")


## show an expr
#function show(io::PrettyIO, ex::Expr)
function show(io::IO, ex::Expr)
    io = pretty(io)
    const infix = {:(=)=>"=", :(.)=>".", doublecolon=>"::", :(:)=>":",
                   :(->)=>"->", :(=>)=>"=>",
                   :(&&)=>" && ", :(||)=>" || "}
    const parentypes = {:call=>("(",")"), :ref=>("[","]"), :curly=>("{","}")}

    head = ex.head
    args = ex.args
    nargs = length(args)

    if has(infix, head) && nargs==2             # infix operations
#        pprint(io, "(",indent(args[1], infix[head], args[2]),")")
        pprint(io, indent(args[1], infix[head], args[2]))
    elseif has(parentypes, head) && nargs >= 1  # :call/:ref/:curly
        pprint(io, args[1])
        pshow_comma_list(io, args[2:end], parentypes[head]...)
    elseif (head == :comparison) && (nargs>=3 && isodd(nargs)) # :comparison
        pprint("(",indent(args),")")
    elseif ((contains([:return, :abstract, :const] , head) && nargs==1) ||
            contains([:local, :global], head))
        pshow_comma_list(io, args, string(head)*" ", "")
    elseif head == :typealias && nargs==2
        pshow_delim_list(io, args, string(head)*" ", " ", "")
    elseif (head == :quote) && (nargs==1)       # :quote
        pshow_quoted_expr(io, args[1])
    elseif (head == :line) && (1 <= nargs <= 2) # :line
        let #io=comment(io)
            if nargs == 1
                linecomment = "line "*string(args[1])*": "
            else
                @assert nargs==2
#               linecomment = "line "*string(args[1])*", "*string(args[2])*": "
                linecomment = string(args[2])*", line "*string(args[1])*": "
            end
            pprint(io, "\t#  ", linecomment)
#             if str_fits_on_line(io, strlen(linecomment)+13)
#                 pprint(io, "\t#  ", linecomment)
#             else
#                 pprint(io, "\n", linecomment)
#             end
        end
    elseif head == :if && nargs == 3  # if/else
        pprint(io, 
            "if ", PNest(pshow_body, args[1], args[2]),
            "\nelse ", PNest(pshow_body, args[3]),
            "\nend")
    elseif head == :try && nargs == 3 # try[/catch]
        pprint(io, "try ", PNest(pshow_body, args[1]))
        if !(is(args[2], false) && is_expr(args[3], :block, 0))
            pprint(io, "\ncatch ", PNest(pshow_body, args[2], args[3]))
        end
        pprint(io, "\nend")
    elseif head == :let               # :let 
        pprint(io, "let ", 
            PNest(pshow_body, args[2:end], args[1]), "\nend")
    elseif head == :block
        pprint(io, "begin ", PNest(pshow_body, ex), "\nend")
    elseif contains([:for, :while, :function, :if, :type], head) && nargs == 2
        pprint(io, string(head), " ", 
            PNest(pshow_body, args[1], args[2]), "\nend")
    else
        pprint(io, head)
        pshow_comma_list(indent(io), args, "(", ")")
    end
end
