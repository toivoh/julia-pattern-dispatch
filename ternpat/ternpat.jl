
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
#code_node(::FuncNode, arg_exprs...) = :(($arg_exprs[1])($arg_exprs[2:end]...))
function code_node(::FuncNode, arg_exprs...)
    # hack to avoid redundant egal
    # todo: do it in a nice way, and for all sure equivalence relations
    if (length(arg_exprs) == 3) && (arg_exprs[1] == quot(egal))
        if is(arg_exprs[2], arg_exprs[3])
            return quot(true)
        end
    end
    :(($arg_exprs[1])($arg_exprs[2:end]...))
end

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
    source_factor::ValNode
    factors::Set{ValNode}  # mutable
end
function MeetNode(factor::ValNode, factors::ValNode...) 
    MeetNode(factor, Set{ValNode}(factor, factors...))
end
function meet!(dest::MeetNode, sources::ValNode...)
    dest.factors = union(dest.factors, Set{ValNode}(sources...))
    nothing
end

get_deps(node::MeetNode) = node.factors
show(io::IO, node::MeetNode) = print(io, "MeetNode(...)")

get_guards(node::MeetNode) = {egalguard(node, f) for f in node.factors}


# -- Helpers ------------------------------------------------------------------

as_valnode(x::PNode) = x::ValNode
as_valnode(x) = Atom(x)

guard(args...) = Guard(FuncNode((), args))

typeguard(x, T) = guard(isa,  x, T)
egalguard(x, y) = guard(egal, x, y)

meet_guards(guards::Guard...) = Guard(FuncNode(guards, {egal, 0, 0}))

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
