
load("pattern/req.jl")
req("ternpat/utils.jl")
req("pretty/pretty.jl")


egal(x,y) = is(x,y)


# -- PNode hierarchy ----------------------------------------------------------

abstract PNode
abstract   ValNode <: PNode
abstract     Source  <: ValNode


get_args(node::PNode) = get_deps(node)


type Guard{T<:ValNode} <: PNode
    predicate::T
end
get_deps(g::Guard) = {g.predicate}

show(io::IO, g::Guard) = print(io, enclose("Guard(", g.predicate, ")"))

type FuncNode <: ValNode
    guards::Set{Guard}
    args::Vector{ValNode}
end
function FuncNode(guards, args) 
    FuncNode(Set{Guard}(guards...), ValNode[map(as_valnode, args)...])
end

get_deps(node::FuncNode) = {node.guards..., node.args...}
get_args(node::FuncNode) = node.args
code_node(::FuncNode, arg_exprs...) = :(($arg_exprs[1])($arg_exprs[2:end]...))

function show(io::IO, node::FuncNode)
    print(io, enclose("FuncNode(", {node.guards...}, ", ", node.args))
end


type VarNode <: Source
    name::Symbol
end
code_node(node::VarNode) = node.name
type Atom{T} <: Source
    value::T
end
code_node(node::Atom) = quot(node.value)

egal(x::Atom, y::Atom) = egal(x.value, y.value)
isequal(x::Atom, y::Atom) = egal(x, y)
hash(x::Atom) = hash(x.value)


get_deps(::Source) = ()


type MeetNode <: ValNode
#    name::VarNode
    factors::Set{ValNode}  # mutable
end
MeetNode(factors...) = MeetNode(Set{ValNode}(factors...))
get_deps(node::MeetNode) = node.factors

show(io::IO, node::MeetNode) = print(io, "MeetNode(...)")

function meet!(dest::MeetNode, sources::ValNode...)
    dest.factors = union(dest.factors, Set{ValNode}(sources...))
    nothing
end


# -- Helpers ------------------------------------------------------------------

as_valnode(x::PNode) = x::ValNode
as_valnode(x) = Atom(x)

guard(args...) = Guard(FuncNode((), args))

typeguard(x, T) = guard(isa,  x, T)
egalguard(x, y) = guard(egal, x, y)


macro ternpat(args...)
    code_ternpat(args...)
end
function code_ternpat(args...)
    guards = args[2:end]
    call = args[1]
    @expect is_expr(call, :call)
    quote
        FuncNode({$guards...}, {$call.args...})
    end
end
