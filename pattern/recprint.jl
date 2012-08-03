
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

record(io::PrintRecorder, arg::Char) = record(io, string(arg))
function record(io::PrintRecorder, arg::String) 
    if length(arg) == 0 return end

    items = io.dest.items
    if (length(items) > 0) && isa(items[end], String)
        items[end] = strcat(items[end], arg)
    else
        push(io.dest.items, arg)
    end
    nothing
end
function record(io::PrintRecorder, node::PrintNode)
    if length(node.items) == 0 return end        
    push(io.dest.items, node)
    nothing
end
record(io::PrintRecorder, arg) = (push(io.dest.items, arg); nothing)


ioprint(io::PrintRecorder, arg) = record(io, arg)

print(io::PrintRecorder, node::GroupNode) = print(io, node.items...)
function print(io::PrintRecorder, node::PrintNode)
    dest = PrintNode(node.env)

    node_io = PrintRecorder(dest, io.objects)
    print(node_io, node.items...)

    record(io, dest)
end

function print(io::PrintRecorder, x) 
    record(io, record_show(io.objects, x))
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

function isshort(node::PrintNode) 
    items = node.items
    (length(items) == 1) && isa(items[1], String) && (length(items[1]) <= 10)
end

function treeify(topnodes::Vector{ObjNode}, node::ObjNode)
    if isshort(node) node.env.reused = false end
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
