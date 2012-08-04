
require("pattern/customio.jl")
require("pattern/utils.jl")

abstract PrintEnv

type PrintNode{T<:PrintEnv}
    env::T
    items::Vector

    PrintNode(env::T, args...) = new(env, {args...})
end
PrintNode{T}(env::T, args...) = PrintNode{T}(env, args...)

# default: ignore the environment
# override to care
print(io::IO, node::PrintNode) = print(io, node.items...)


type GroupEnv <: PrintEnv; end
typealias GroupNode PrintNode{GroupEnv}

defer_print(args...) = PrintNode(GroupEnv(), args...)

comma_list() = ""
function comma_list(first, args...)
    items = {first}
    for arg in args
        push(items, ", ")
        push(items, arg)
    end
    defer_print(items...)
end


type IndentEnv <: PrintEnv; end
typealias IndentNode PrintNode{IndentEnv}

indent(args...) = PrintNode(IndentEnv(), args...)
enclose(args...) = defer_print(args[1], indent(args[2:end-1]...), args[end])


# ---- PrintExpander ----------------------------------------------------------

type PrintExpander <: CustomIO
    parts::Vector
    PrintExpander() = new({})
end
@customio PrintExpander

print(io::PrintExpander, node::GroupNode) = print(io, node.items...)
function print(io::PrintExpander, node::PrintNode)
    items = vcat({expand_print(item) for item in node.items}...)
    push(io.parts, PrintNode(node.env, items...))
    nothing
end
#ioprint(io::PrintExpander, arg::String) = (push(io.parts, arg); nothing)
ioprint(io::PrintExpander, arg) = (push(io.parts, arg); nothing)

function expand_print(arg)
    io = PrintExpander()
    print(io, arg)
    io.parts
end


# ---- PrettySimple -----------------------------------------------------------

type PrettySimple <: CustomIO
    sink::IO
    indent::Int
    freshline::Bool
    newnode::Bool

    PrettySimple(sink::IO) = new(sink, 0, false, false)
end
@customio PrettySimple

ioprint(io::PrettySimple, s::String) = (for c in s; ioprint(io, c); end)
function ioprint(io::PrettySimple, c::Char)
    if io.newnode && !io.freshline
        print(io.sink, '\n')
        io.freshline = true
    end
    io.newnode = false

    if io.freshline
        print(io.sink, " "^io.indent)
    end
    io.freshline = false
    print(io.sink, c)
    if c == '\n'
        io.freshline = true
    end
end

function print(io::PrettySimple, node::IndentNode)
    indent = 2
    io.indent += indent
    printnode(io, node)
    io.indent -= indent
    nothing
end

print(io::PrettySimple, node::GroupNode) = print(io, node.items...)
print(io::PrettySimple, node::PrintNode) = printnode(io, node)

function printnode(io::PrettySimple, node::PrintNode)
    io.newnode = true
    print(io, node.items...)
    io.newnode = true
end


pretty(io::PrettySimple) = io
pretty(io::IO) = PrettySimple(io)

pprint(io::PrettySimple, args...) = print(io, args...)
pprint(io::IO, args...) = print(pretty(io), args...)
pprint(args...) = pprint(OUTPUT_STREAM, args...)

pshow(io::PrettySimple, args...) = show(io, args...)
pshow(io::IO, args...) = show(pretty(io), args...)
pshow(args...) = pshow(OUTPUT_STREAM, args...)


peel(node::PrintNode) = length(node.items) == 1 ? node.items[1] : node
peel(arg) = arg

function undent(width::Int, node::PrintNode)
    if isa(node, IndentNode)
        width -= 2
    end
    items = {undent(width, item) for item in node.items}
    
    items2 = {peel(item) for item in items}

#     if all({isa(item, String) for item in items}) && 
#        (sum({strlen(item) for item in items}) < width)
#         return strcat(items...)
#     end
    if all({isa(item, String) for item in items2})
        s = strcat(items2...)
        if !contains(s, '\n') && (strlen(s) < width)
#             @show s
#             @show width
             return PrintNode(node.env, s)
        end
    end
    PrintNode(node.env, items...)
end

undent(width::Int, arg) = arg
