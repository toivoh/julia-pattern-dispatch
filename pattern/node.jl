
require("pattern/prettyprint.jl")

abstract Node
abstract   Event <: Node  # Node that for an action: Guard/Assign
abstract   Value <: Node  # Node that produces a value
abstract     Independent <: Value  # Node that might take on any value
abstract     Computation <: Value  # Value that can be computed (from its deps)
abstract       Source <: Computation  # Computation without dependencies


abstract Subs

ref{T}(s::Subs, xs::Vector{T}) = T[{s[xs] for x in xs}...]


## Terminals ##

type Atom{T} <: Source
    value::T
end
Atom{T}(x::T) = Atom{T}(x)
type Arg <: Source
end

#show(io::IO, node::Atom) = print(io, "Atom(", node.value, ")")

type Variable <: Independent
    name::Symbol
end

typealias Leaf Union(Source, Variable)

links(node::Leaf) = ()
subslinks(s::Subs, node::Leaf) = node


## Functions ##

abstract FuncFun

type ApplyFun <: FuncFun; end
type IsaFun   <: FuncFun; end
type EgalFun  <: FuncFun; end
type AndFun   <: FuncFun; end


type Func{F<:FuncFun} <: Computation
    args::Vector{Node}  # Vector{Union(Value,NodeSet)}
    
    Func(args::Vector{Node}) = new(args)
    Func(args::Node...) = new(Node[args...])
end
links(node::Func) = node.args
subslinks{F}(s::Subs, node::Func{F}) = Func{F}(s[node.args])

typealias Apply Func{ApplyFun}
typealias Isa   Func{IsaFun}
typealias Egal  Func{EgalFun}
typealias And   Func{AndFun}

show(io::IO, node::Apply) = showfunc(io, node, "Apply")
show(io::IO, node::Isa)   = showfunc(io, node, "Isa")
show(io::IO, node::Egal)  = showfunc(io, node, "Egal")
show(io::IO, node::And)   = showfunc(io, node, "And")
function showfunc(io::IO, node::Func, name::String)
    print(io, name, enclose("(", comma_list(node.args...), ")"))
end


## Gated computations ##

## value is not made available until the guard has been verified
type Gate <: Computation
    value::Node  # Value
    guard::Node  # Guard
end
links(node::Gate) = (node.value, node.guard)
subslinks(s::Subs, node::Gate) = Gate(s[node.value], s[node.guard])


## Events ##

type Guard <: Event
    pred::Node  # Value
end
links(node::Guard) = (node.pred,)
subslinks(s::Subs, node::Guard) = Guard(s[node.pred])

type Assign <: Event
    target::Node  # Variable
    value::Node   # Value
end
links(node::Assign) = (node.target, node.value)
subslinks(s::Subs, node::Assign) = Assign(s[node.target], s[node.value])


## Other ##

type NodeSet{T<:Node} <: Node
    nodes::Set{T}
    
    NodeSet(nodes::Set{T}) = new(nodes)
    NodeSet(nodes::T...) = new(Set{T}(nodes...))
end
#NodeSet{T}(nodes::Vector{T}) = NodeSet{T}(nodes...)
links(node::NodeSet) = node.nodes
function subslinks{T}(s::Subs, node::NodeSet{T})
    NodeSet{T}(Set{T}( {s[x] for x in node.nodes}... ))
end

function show(io::IO, nodes::NodeSet)
    print(io, enclose("Nodeset(", comma_list(nodes.nodes...), ")"))
end

type Link{T<:Node} <: Node
    target::T
end
links(node::Link) = (node.target,)
#subslinks(s::Subs, node::Link) = (node.target = s[node.target]; node)

