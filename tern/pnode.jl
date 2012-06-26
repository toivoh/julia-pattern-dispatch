
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


