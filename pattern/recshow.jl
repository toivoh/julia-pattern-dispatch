
require("pattern/customio.jl")

type RecorderIO <: CustomIO
    dest::Vector
    prints::ObjectIdDict
end
RecorderIO() = RecorderIO({}, ObjectIdDict())

##  Methods to redirect strings etc output to a RecorderIO to one place ##
print(io::RecorderIO, c::Char) = print_char(io, c)
for S in [:ASCIIString, :UTF8String, :RopeString, :String]
    @eval print(io::RecorderIO, s::($S)) = print_str(io, s)
end


function enter(io::RecorderIO, x)
    @assert !has(io.prints, x)
    dest = {false}
    io.prints[x] = dest
    RecorderIO(dest, io.prints)
end

function print(io::RecorderIO, x)
    push(io.dest, x)
    if has(io.prints, x); 
        io.prints[x][1] = gensym()
        return
    end
    show(enter(io, x), x)
end

print_str(io::RecorderIO, s::String) = (push(io.dest, s); nothing)
print_char(io::RecorderIO, c::Char) = print_str(io, string(c))

function record_show(arg)
    io = RecorderIO()
    show(enter(io, arg), arg)
    io.prints
end


type RecShow
    io::IO
    prints::ObjectIdDict
    printed::ObjectIdDict
    queue::Vector
end

function recshow(io::IO, arg)
    prints = record_show(arg)
    c = RecShow(io, prints, ObjectIdDict(), {arg})
    prints[arg][1] = :arg
    while !isempty(c.queue)
        arg = shift(c.queue)
        print(c.prints[arg][1], "\t= ")
        recshow(c, arg)
        println(io)
    end
end

recprint(c::RecShow, arg::String) = print(c.io, arg)
function recprint(c::RecShow, arg)
    p = c.prints[arg]
    if is(p[1], false)
        recshow(c, arg)
    else
        print(c.io, p[1]) # print the name
        if !has(c.printed, arg)
            c.printed[arg] = true
            push(c.queue, arg)
        end
    end
end

function recshow(c::RecShow, arg)
    parts = c.prints[arg]
    parts = parts[2:]
    for part in parts
        recprint(c, part)
    end
end

recshow(arg) = recshow(OUTPUT_STREAM, arg)
