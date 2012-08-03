
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

function treeify(topnodes::Vector{ObjNode}, node::ObjNode)
    if is(node.env.reused, false)
        return treeify(topnodes, defer_print(node.items...))    
    end

    if is(node.env.reused, true)
        # Name the node and add it to the print list
        k = length(topnodes)
        node.env.reused = "<x$(k)>"
        push(topnodes, node)
    end    

    node.env.reused  # Return the name
end
function treeify(topnodes::Vector{ObjNode}, node::PrintNode)
    PrintNode(node.env, {treeify(topnodes, item) for item in node.items}...)
end

treeify(topnodes::Vector{ObjNode}, arg) = arg


function treeify(node::ObjNode)
    node.env.reused = "<obj>"
    topnodes = ObjNode[node]
    toprint = {}
    k = 1
    while k <= length(topnodes)
        tree = treeify(topnodes, defer_print(topnodes[k].items...))
        push(toprint, defer_print(topnodes[k].env.reused, " =", indent(tree)))
#        push(toprint, defer_print(topnodes[k].env.reused, " =\n", tree, '\n'))
        k += 1
    end
    
    defer_print(toprint...)
end


recshow(arg) = recshow(OUTPUT_STREAM, arg)
function recshow(io::IO, arg)
    pprint(io, treeify(record_show(arg)))
end
