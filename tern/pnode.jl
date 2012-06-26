
quot(ex) = expr(:quote, ex)


egal(x) = true
egal(x,y,z,args...) = egal(x,y) && egal(y,z,args...)

egal(x,y) = is(x,y)
egal{T<:Number}(x::T, y::T) = isequal(x, y)
egal{T<:Tuple}(xs::T, ys::T) = all({egal(x,y) for (x,y) in zip(xs,ys)})



# -- PNode --------------------------------------------------------------------
abstract PNode
abstract   SourceNode <: PNode
abstract   FNode <: PNode

## SourceNode:s
type VarNode <: SourceNode
    name::Symbol
end
type AtomNode{T} <: SourceNode
    value::T
end

## FNode:s
type FuncNode <: FNode
    args::Vector{PNode}
end
FuncNode(args...) = FuncNode(PNode[args...])

type IsaNode <: FNode
    x::PNode
    T::PNode
end

type AndNode <: FNode
    args::Set{PNode}
end

type EgalNode <: FNode
    args::Set{PNode}
end

## Other PNode:s
type GateNode <: PNode
    value::PNode
    condition::PNode
end

type AltNode <: PNode
    sources::Set{PNode}
end

get_args(node::SourceNode) = ()

get_args(node::FuncNode) = node.args
get_args(node::IsaNode) = (node.x, node.T)
get_args(node::AndNode) = node.args
get_args(node::EgalNode) = node.args

get_args(node::GateNode) = node.value, node.condition


code_apply(arg_exprs...) = :(($arg_exprs[1])($arg_exprs[2:end]...))

code_node(node::VarNode) = node.name
code_node(node::AtomNode) = quot(node.value)

code_node(::FuncNode, arg_exprs...) = code_apply(arg_exprs...)
code_node(::IsaNode, x, T) = code_apply(isa, x, T)
code_node(::AndNode, args...) = code_apply(all, args...) # todo: short circuit
code_node(::EgalNode, args...) = code_apply(egal, args...)

code_node(::GateNode, value, cond) = :(($cond)?($value):nothing)
