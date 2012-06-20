
load("pattern/req.jl")
req("ternpat/utils.jl")
req("pretty/pretty.jl")


egal(x,y) = is(x,y)
egal{T<:Number}(x::T, y::T) = isequal(x, y)
egal{T<:Tuple}(xs::T, ys::T) = all({egal(x,y) for (x,y) in zip(xs,ys)})


# -- PNode hierarchy ----------------------------------------------------------

abstract PNode
abstract   ValNode <: PNode
abstract     FNode   <: ValNode
abstract       Source  <: FNode


## PNodeSet
typealias PNodeSet Set{PNode}

as_pnodeset(node::PNode) = PNodeSet(node)
as_pnodeset(s::PNodeSet) = s
pnodeset(nodes::PNode...) = PNodeSet(nodes...)
pnodeset(args...) = union(map(as_pnodeset, args)...)


## Guard
type Guard <: PNode
    predicate::ValNode
end

## MeetNode
type MeetNode <: ValNode
    primary_factor::ValNode
    factors::Set{ValNode}  # mutable    
end
function MeetNode(primary_factor::ValNode, factors::ValNode...) 
    MeetNode(primary_factor, Set{ValNode}(primary_factor, factors...))
end
MeetNode(args...) = MeetNode(as_valnodes(args)...)


## VarNode and Atom <: Source
type VarNode <: Source
    name::Symbol
end
type Atom{T} <: Source
    value::T
end
egal(x::Atom, y::Atom) = egal(x.value, y.value)
isequal(x::Atom, y::Atom) = egal(x, y)
hash(x::Atom) = hash(x.value)

## FuncNode
type FuncNode <: ValNode
    deps::PNodeSet
    args::Vector{ValNode}
end
FuncNode(deps,args) = FuncNode(pnodeset(deps...),ValNode[as_valnodes(args)...])
FuncNode(dep::PNode, args) = FuncNode((dep,), args)


## PNode methods

get_deps(node::Guard) = (node.predicate,)
get_args(node::Guard) = (node.predicate,)

get_deps(node::FuncNode) = node.deps
get_args(node::FuncNode) = node.args

get_deps(::PNode)  = ()
get_args(::Source) = ()


code_node(node::VarNode) = node.name
code_node(node::Atom) = quot(node.value)
code_node(::FuncNode, arg_exprs...) = :(($arg_exprs[1])($arg_exprs[2:end]...))

#show(io::IO, g::Guard) = print(io, enclose("Guard(", g.predicate, ")"))
show(io::IO, node::MeetNode) = print(io, "MeetNode(...)")
function show(io::IO, node::FuncNode)
    print(io, enclose("FuncNode(", node.args, ", ", {node.deps...}, ")"))
end


# -- Helpers ------------------------------------------------------------------

as_valnodes(args) = map(as_valnode, args)

as_valnode(x::PNode) = x::ValNode
as_valnode(x) = Atom(x)


typeguard(x, T) = Guard(FuncNode((), (isa, x, T)))

egaldep(x::ValNode, y::ValNode) = pnodeset(x, y, MeetNode(x,y))
egaldep(args...) = egaldep(as_valnodes(args)...)

macro ternpat(args...)
    code_ternpat(args...)
end
function code_ternpat(arg)
    g,call = is_expr(arg,:block) ? (arg.args[1:end-1],arg.args[end]) : ({},arg)
    @expect is_expr(call, :call)
    quote
        FuncNode({$g...}, {$call.args...})
    end
end
