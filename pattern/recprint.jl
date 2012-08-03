
require("pattern/prettyprint.jl")


type ObjEnv <: PrintEnv
    obj
    reused

    ObjEnv(obj) = new(obj, false)
end
typealias ObjNode PrintNode{ObjEnv}


type PrintRecorder <: CustomIO
    dest::PrintNode
    objects::ObjectIdDict

    PrintRecorder(dest::PrintNode, objects::ObjectIdDict) = new(dest, objects)
end
@customio PrintRecorder

function enter(objects::ObjectIdDict, obj)
    @assert !has(objects, obj)
    dest = ObjNode(ObjEnv(obj))
    objects[obj] = dest
    PrintRecorder(dest, objects)
end


ioprint(io::PrintRecorder, arg) = (push(io.dest.items, arg); nothing)

function print(io::PrintRecorder, node::PrintNode)
    dest = PrintNode(node.env)
    push(io.dest.items, dest)

    node_io = PrintRecorder(dest, io.objects)
    print(node_io, node.items...)
end

function print(io::PrintRecorder, x) 
    push(io.dest.items, record_show(io.objects, x))
    nothing
end

function record_show(objects::ObjectIdDict, x)
    if has(objects, x)
        node = objects[x]::ObjNode
        node.env.reused = true
        node
    else
        io = enter(objects, x)
        show(io, x)
        io.dest
    end
end


record_show(arg) = record_show(ObjectIdDict(), arg)
