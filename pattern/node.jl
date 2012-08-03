
require("pattern/prettyprint.jl")

abstract Node
abstract   Result <: Node
abstract     Computation <: Result
abstract       Source <: Computation
abstract     Value <: Result
abstract   Event <: Node
abstract     Condition <: Event


abstract Subs

ref{T}(s::Subs, xs::Vector{T}) = T[{s[xs] for x in xs}...]


## Sources ##

type Atom{T} <: Source
    value::T
end
Atom{T}(x::T) = Atom{T}(x)
type Arg <: Source
end

show(io::IO, node::Atom) = print(io, "Atom(", node.value, ")")

links(node::Source) = ()
subslinks(s::Subs, node::Source) = node


## Functions ##

abstract FuncFun

type Func{F<:FuncFun} <: Computation
    args::Vector{Node}  # Vector{Union(Result,Set)}
    
    Func(args::Vector{Node}) = new(args)
    Func(args::Node...) = new(Node[args...])
end
links(node::Func) = node.args
subslinks{F}(s::Subs, node::Func{F}) = Func{F}(s[node.args])

type ApplyFun <: FuncFun; end
type IsaFun   <: FuncFun; end
type EgalFun  <: FuncFun; end
type AndFun   <: FuncFun; end

typealias Apply Func{ApplyFun}
typealias Isa   Func{IsaFun}
typealias Egal  Func{EgalFun}
typealias And   Func{AndFun}

show(io::IO, node::Apply) = showfunc(io, node, "Apply")
show(io::IO, node::Isa)   = showfunc(io, node, "Isa")
show(io::IO, node::Egal)  = showfunc(io, node, "Egal")
show(io::IO, node::And)   = showfunc(io, node, "And")
#showfunc(io::IO, node::Func, name::String) = print(io,name,tuple(node.args...))
function showfunc(io::IO, node::Func, name::String)
    print(io, name, enclose("(", comma_list(node.args...), ")"))
end


## Gated computations ##

## value is not made available until the guard has been verified
type Gate <: Computation
    value::Node  # Result
    guard::Node  # Condition
end
links(node::Gate) = (node.value, node.guard)
subslinks(s::Subs, node::Gate) = Gate(s[node.value], s[node.guard])

## Values ##

type Variable <: Value
    name::Symbol
end
links(node::Variable) = ()
subslinks(s::Subs, node::Variable) = node


## Events ##

type Guard <: Condition
    pred::Node  # Result
end
links(node::Guard) = (node.pred,)
subslinks(s::Subs, node::Guard) = Guard(s[node.pred])

type Assign <: Event
    target::Node  # Variable
    value::Node   # Result
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

