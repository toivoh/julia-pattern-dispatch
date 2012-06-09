
macro expect(pred)
    quote
        ($pred) ? nothing : error("expected: ", ($string(pred))", == true")
    end
end

is_expr(ex, head::Symbol) = (isa(ex, Expr) && (ex.head == head))
function is_expr(ex, head::Symbol, nargs::Int)
    is_expr(ex, head) && length(ex.args) == nargs
end

is_quoted(ex::QuoteNode) = true
is_quoted(ex::Expr)      = is_expr(ex, :quote, 1)
is_quoted(ex)            = false

unquoted(ex::QuoteNode) = ex.value
unquoted(ex::Expr)      = (@assert is_quoted(ex); ex.args[1])


# -- PrettyIO -----------------------------------------------------------------

abstract PrettyIO <: IO

##  Methods to redirect strings etc output to a PrettyIO to one place ##
print(io::PrettyIO, c::Char) = print_char(io, c)
for S in [:ASCIIString, :UTF8String, :RopeString, :String]
    @eval print(io::PrettyIO, s::($S)) = print_str(io, s)
end
show(io::PrettyIO, s::Symbol) = print(io, string(s))


print_str(io::PrettyIO, s::String) = (for c in s; print_char(io, c); end)

# pprintln/pprint/pshow: make sure to use a PrettyIO, then println/print/show
pprintln(args...) = pprint(args..., '\n')
pprint(io::IO, args...) = print(pretty(io), args...)
pshow(io::IO, args...) = show(pretty(io), args...)
pprint(args...) = pprint(OUTPUT_STREAM, args...)
pshow(args...) = pshow(OUTPUT_STREAM, args...)

# fix to avoid jl_show_any on PrettyIO (segfaults)
function show(io, x) 
    io::IO
    if isa(io, PrettyIO)
#        print(io, sshow(x))
        default_show(io, x)
    elseif isa(io, IOStream)
        ccall(:jl_show_any, Void, (Any, Any,), io, x)
    else
        error("unimplemented!")
    end
end


default_show(io::IO, x) = default_show(io, typeof(x), x)

const null_symbol = symbol("")

default_show(io, T, x) = sshow(x) # works as long as it invokes jl_show_any...
function default_show(io, T::CompositeKind, x)
    fields = filter(x->(x!=null_symbol), [T.names...])
#     for field in fields
#         value = getfield(x, field)
#         print(value)
#     end
    values = {getfield(x, field) for field in fields}
    print(io, sshow(T), enclose("(", comma_list(values...), ")"))
#    print(io, sshow(T), enclose("(", comma_list(fields...), ")"))
end


## -- PrettyTerm --------------------------------------------------------------
# Basic pretty terminal. Keeps track of column position and line width.

type PrettyTerm <: PrettyIO
    sink::IO
    width::Int
    xpos::Int
    fresh_line::Bool

    function PrettyTerm(sink::IO, width::Int)
        @expect width > 0
        new(sink, width, 0, false)
    end
end

function print_char(io::PrettyTerm, c::Char)
    io.fresh_line = false
    if c=='\t'       # Tab
        for k=1:((-io.xpos)&7)
            print(io.sink, ' ')
            io.xpos += 1
        end
    elseif c=='\x1f' # Unit separator: don't print
    else             # Other chars. todo: handle other special chars?
        print(io.sink, c)
        io.xpos += 1
        if c == '\n'
            io.xpos = 0
            io.fresh_line = true
        end
    end
end


## -- PrettyStream ------------------------------------------------------------
# Basic pretty printing context. Keeps track of indenting and line wrapping.

type PrettyStream <: PrettyIO
    parent::PrettyTerm
    indent::Int
    wrap::Bool

    PrettyStream(parent::PrettyTerm, indent::Int) = new(parent, indent, true)
end

pretty(io::PrettyIO) = io
pretty(io::PrettyTerm) = PrettyStream(io, 0)
pretty(io::IO) = pretty(PrettyTerm(io, 79))

indented(io::PrettyStream) = PrettyStream(io.parent, io.indent+4)
indented(io::IO) = indented(pretty(io))

function print_char(io::PrettyStream, c::Char)
    if io.wrap && (io.parent.xpos >= io.parent.width)  # wrap
        print_char(io.parent, '\n') 
    end  
    if io.parent.fresh_line && (io.indent > 0)        # indent
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


# -- PNest --------------------------------------------------------------------

type PNest
    f::Function
    extra_args::Tuple

    PNest(f::Function, extra_args...) = new(f, extra_args)
end
print(io::IO, nest::PNest) = nest.f(io, nest.extra_args...)


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
delim_list(args, post) = delim_list(args, "", post)

comma_list(args...) = delim_list(args, ", ")

function enclose(args...) 
    PNest(io->(print(io,args[1],indent(args[2:end-1]...),args[end])))
end


# == Expr prettyprinting ======================================================

const doublecolon = (:(::Int)).head

## show the body of a :block
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
nest_mainbody(ex) = PNest(pshow_mainbody, ex)

## show arguments of a block, and then body
pshow_body(io::PrettyIO, body) = pshow_body(io, {}, body)
function pshow_body(io::PrettyIO, arg, body)
    pprint(io, indent(arg, nest_mainbody(body) ))
end
function pshow_body(io::PrettyIO, args::Vector, body)
    pprint(io, indent(
            comma_list(args...),
            nest_mainbody(body)
        ))
end
nest_body(args...) = PNest(pshow_body, args...)

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
        pprint(io, "quote ", nest_body(ex), "\nend")
    else
        pprint(io, enclose("quote(", ex, ")"))
    end
end
pshow_quoted_expr(io::PrettyIO, ex) = pprint(io, enclose(":(", ex, ")"))


## show an expr
#function show(io::PrettyIO, ex::Expr)
function show(io::IO, ex::Expr)
    io = pretty(io)
    const infix = {:(=)=>"=", doublecolon=>"::", :(:)=>":",
                   :(->)=>"->", :(=>)=>"=>",
                   :(&&)=>" && ", :(||)=>" || "}
    const parentypes = {:call=>("(",")"), :ref=>("[","]"), :curly=>("{","}")}

    head = ex.head
    args = ex.args
    nargs = length(args)

    if head == :(.)
        print(io, '\x1f', indent(args[1], ".",
            is_quoted(args[2]) ? unquoted(args[2]) : enclose("(", args[2], ")")
#             is_expr(args[2], :quote, 1) ? 
#             args[2].args[1] : enclose("(", args[2], ")")
        ), '\x1f')
    elseif has(infix, head) && nargs==2         # infix operations
#        pprint(io, "(",indent(args[1], infix[head], args[2]),")")
        pprint(io, '\x1f', indent(args[1], infix[head], args[2]), '\x1f')
    elseif has(parentypes, head) && nargs >= 1  # :call/:ref/:curly
        print(io, args[1], enclose(parentypes[head][1], 
            comma_list(args[2:end]...),
        parentypes[head][2]))
    elseif (head == :comparison) && (nargs>=3 && isodd(nargs)) # :comparison
        pprint("(",indent(args),")")
    elseif ((contains([:return, :abstract, :const] , head) && nargs==1) ||
            contains([:local, :global], head))
        print(io, string(head)*" ", indent(comma_list(args...)))
    elseif head == :typealias && nargs==2
        print(io, string(head)*" ", indent(args[1], " ", args[2]))
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
            "if ", nest_body(args[1], args[2]),
            "\nelse ", nest_body(args[3]),
            "\nend")
    elseif head == :try && nargs == 3 # try[/catch]
        pprint(io, "try ", nest_body(args[1]))
        if !(is(args[2], false) && is_expr(args[3], :block, 0))
            pprint(io, "\ncatch ", nest_body(args[2], args[3]))
        end
        pprint(io, "\nend")
    elseif head == :let               # :let 
        pprint(io, "let ", 
            nest_body(args[2:end], args[1]), "\nend")
    elseif head == :block
        pprint(io, "begin ", nest_body(ex), "\nend")
    elseif contains([:for, :while, :function, :if, :type], head) && nargs == 2
        pprint(io, string(head), " ", 
            nest_body(args[1], args[2]), "\nend")
    else
        print(io, head, enclose("(", comma_list(args...), ")"))
    end
end
