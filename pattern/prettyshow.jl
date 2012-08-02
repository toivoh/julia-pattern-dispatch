
require("pattern/customio.jl")
require("pattern/utils.jl")


abstract PrintControl
abstract PrintEnv

type BeginEnv <: PrintControl
    env::PrintEnv
end
type EndEnv   <: PrintControl
    env::PrintEnv
end

type Breakable <: PrintControl; end
const breakable = Breakable()

type IndentEnv <: PrintEnv; end
const indentenv = IndentEnv()




type PrettyTerm <: CustomIO
    sink::IO
    width::Int

    xpos::Int
    fresh_line::Bool
    envstack::Vector{PrintEnv}
    indent::Integer
    wrap::Bool

    function PrettyTerm(sink::IO, width::Int)
        @expect width > 0
        new(sink, width, 0, false, PrintEnv[], 0, true)
    end
end
@customio PrettyTerm

pretty(io::PrettyTerm) = io

pretty(io::IO, width::Int) = PrettyTerm(io, width)
pretty(io::IO) = pretty(io, 79)
pretty(io::IO, args...) = error("unimplemented!")
pretty(args...) = pretty(OUTPUT_STREAM, args...)

pprint(io::PrettyTerm, args...) = print(io, args...)
pprint(io::IO, args...) = print(pretty(io), args...)
pprint(args...) = pprint(OUTPUT_STREAM, args...)

pshow(io::PrettyTerm, args...) = show(io, args...)
pshow(io::IO, args...) = show(pretty(io), args...)
pshow(args...) = pshow(OUTPUT_STREAM, args...)



#print(io::PrettyTerm, ::Breakable) = (io.fresh_line = false; nothing)
function rawprint(io::PrettyTerm, c::Char)
    io.fresh_line = false
    if c=='\t'       # Tab
        for k=1:((-io.xpos)&7)
            print(io.sink, ' ')
            io.xpos += 1
        end
#    elseif c=='\x1f' # Unit separator: don't print
    else             # Other chars. todo: handle other special chars?
        print(io.sink, c)
        io.xpos += 1
        if c == '\n'
            io.xpos = 0
            io.fresh_line = true
        end
    end
end

function print_char(io::PrettyTerm, c::Char)
    if io.wrap && (io.xpos >= io.width)  # wrap
        rawprint(io, '\n') 
    end  
    if io.fresh_line && (io.indent > 0)        # indent
        for k=1:io.indent; rawprint(io, ' '); end
        io.wrap = (2*io.xpos >= io.width)
    end
    rawprint(io, c)
end


function print(io::PrettyTerm, c::BeginEnv)
    push(io.envstack, c.env)
    enter(io, c.env)
end
function print(io::PrettyTerm, c::EndEnv)
    @assert is(pop(io.envstack), c.env)
    leave(io, c.env)
end

enter(io::PrettyTerm, ::IndentEnv) = (io.indent += 1; nothing)
leave(io::PrettyTerm, ::IndentEnv) = (io.indent -= 1; nothing)

