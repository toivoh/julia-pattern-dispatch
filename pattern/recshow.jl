
require("pattern/customio.jl")

type ObjRec
    obj
    name
    parts::Vector

    ObjRec(obj) = new(obj, false, {})
end

type RecorderIO <: CustomIO
    dest::ObjRec
    objects::ObjectIdDict
end
RecorderIO(dest::ObjRec) = RecorderIO(dest, ObjectIdDict())

## Redirect direct output to a RecorderIO into print_str and print_char
@customio RecorderIO


print_str(io::RecorderIO, s::String) = (push(io.dest.parts, s); nothing)
print_char(io::RecorderIO, c::Char) = print_str(io, string(c))

print(io::RecorderIO, x) = (push(io.dest.parts, record_show(io, x)); nothing)

function record_show(io::RecorderIO, x)
    if has(io.objects, x)
        p = io.objects[x]
        if isa(p, ObjRec) && is(p.name, false);  p.name = true;  end
        p
    else
        io = enter(io, x)
        show(io, x)        
#        io.dest
        return io.objects[x] = simplify(io.dest)
    end
end

function enter(io::RecorderIO, x)
    @assert !has(io.objects, x)
    dest = ObjRec(x)
    io.objects[x] = dest
    RecorderIO(dest, io.objects)
end

record_show(arg) = record_show(RecorderIO(ObjRec(arg)), arg)


function simplify(p::ObjRec)
    if allp(part->isa(part, String), p.parts)
        s = strcat(p.parts...)
        if strlen(s) <= 10
            return s
        end
        p.parts = [s]
    end
    p
end




type RecShow
    io::IO
    printed::Set{ObjRec}
    queue::Vector{ObjRec}
    numnames::Integer

    RecShow(io::IO, queue) = new(io, Set{ObjRec}(), ObjRec[queue...], 0)
end

recshow(arg) = recshow(OUTPUT_STREAM, arg)
function recshow(io::IO, arg)
    p = record_show(arg)
    if !isa(p, ObjRec)
        println(io, p)
        return
    end
    p.name = :arg
    c = RecShow(io, {p})
    while !isempty(c.queue)
        p = shift(c.queue)
        print(p.name, "\t= ")
        recprint(c, p.parts...)
        println(io)
    end
end

recprint(c::RecShow, arg::String) = print(c.io, arg)
recprint(c::RecShow, args...) = (for arg in args; recprint(c, arg); end)

function recprint(c::RecShow, p::ObjRec)
    if is(p.name, false)
        recprint(c, p.parts...)
    else
        if !has(c.printed, p)
            add(c.printed, p)
            push(c.queue, p)
            c.numnames += 1
            p.name = "_x$(c.numnames)"
        end
        print(c.io, p.name) # print the name
    end
end


