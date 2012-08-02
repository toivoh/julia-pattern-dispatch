
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


type PrettySimple <: CustomIO
    sink::IO
    indent::Int
    freshline::Bool

    PrettySimple(sink::IO) = new(sink, 0, false)
end
@customio PrettySimple

function ioprint(io::PrettySimple, c::Char)
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
    if node.items=={""}; return; end
    indent = 2
    io.indent += indent
#    print(io, node.items...)
    print(io, '\n', node.items..., '\n')
    io.indent -= indent
    nothing
end



pretty(io::PrettySimple) = io
pretty(io::IO) = PrettySimple(io)

pprint(io::PrettySimple, args...) = print(io, args...)
pprint(io::IO, args...) = print(pretty(io), args...)
pprint(args...) = pprint(OUTPUT_STREAM, args...)

pshow(io::PrettySimple, args...) = show(io, args...)
pshow(io::IO, args...) = show(pretty(io), args...)
pshow(args...) = pshow(OUTPUT_STREAM, args...)
