

# -- egal ---------------------------------------------------------------------

egal(x) = true
egal(x,y,z,args...) = egal(x,y) && egal(y,z,args...)

egal(x,y) = is(x,y)
egal{T<:Number}(x::T, y::T) = isequal(x, y)
egal{T<:Tuple}(xs::T, ys::T) = all({egal(x,y) for (x,y) in zip(xs,ys)})


# -- PNode --------------------------------------------------------------------
abstract PNode
abstract   SourceNode <: PNode

## SourceNode:s
type VarNode <: SourceNode
    name::Symbol
end
type AtomNode{T} <: SourceNode
    value::T
end

egal(x::AtomNode, y::AtomNode) = egal(x.value, y.value)
isequal(x::AtomNode, y::AtomNode) = egal(x, y)
hash(x::AtomNode) = hash(x.value)


type FuncNode <: PNode
    args::Vector{PNode}
end
FuncNode(args...) = FuncNode(PNode[args...])

type GateNode <: PNode
    value::PNode
    condition::PNode
end


get_args(node::SourceNode) = ()
get_args(node::FuncNode) = node.args


code_apply(arg_exprs...) = :(($arg_exprs[1])($arg_exprs[2:end]...))

code_node(node::VarNode) = node.name
code_node(node::AtomNode) = quot(node.value)
code_node(::FuncNode, arg_exprs...) = code_apply(arg_exprs...)


# -- Helpers ------------------------------------------------------------------

as_pnode(node::PNode) = node
as_pnode(x) = AtomNode(x)

funcnode(args...) = FuncNode(map(as_pnode, args)...)

egalnode(x, y) = funcnode(egal, x, y)
isanode(x, T) = funcnode(isa, x, T)
andnode(args...) = funcnode(all, args...)

is_andnode(node::FuncNode) = node.args[1] == AtomNode(all)
is_andnode(node::PNode) = false
function get_and_factors(node::PNode)
    @assert is_andnode(node)
    node.args[2:end]
end


function get_guards(node::PNode)
    guards = Set{PNode}()
    get_guards(Set{PNode}(), guards, node)
    guards
end
function get_guards(visited::Set{PNode}, guards::Set{PNode}, node::PNode)
    if has(visited, node);  return;  end
    add(visited, node)

    if is_andnode(node)
        for factor in get_and_factors(node)
            get_guards(visited, guards, factor)
        end
    else
        add(guards, node)
    end
    nothing
end
