
require("simptern/immutable.jl")


abstract Subs

ref(s::Subs, args::Tuple) = map(x->s[x], args)


# -- PNode --------------------------------------------------------------------
abstract PNode
abstract   SourceNode <: PNode

## SourceNode:s
type VarNode <: SourceNode
    name::Symbol
end
@immutable type AtomNode{T} <: SourceNode
    value::T
end
AtomNode{T}(x::T) = AtomNode{T}(x)
subs_links(s::Subs, node::SourceNode) = node

# egal(x::AtomNode, y::AtomNode) = egal(x.value, y.value)
# isequal(x::AtomNode, y::AtomNode) = egal(x, y)
# hash(x::AtomNode) = hash(x.value)


@immutable type FuncNode <: PNode
    args::ImmVector{PNode}
    FuncNode(args::ImmVector{PNode}) = new(args)
end
FuncNode(args...) = FuncNode(ImmVector{PNode}(args...))
subs_links(s::Subs, node::FuncNode) = FuncNode(s[node.args])

@immutable type GateNode <: PNode
    value::PNode
    condition::PNode

    GateNode(value::PNode, condition::PNode) = new(value, condition)
end
subs_links(s::Subs, node::GateNode) = GateNode(s[node.value],s[node.condition])


get_args(node::SourceNode) = ()
get_args(node::FuncNode) = node.args

get_links(node::SourceNode) = ()
get_links(node::FuncNode) = node.args
get_links(node::GateNode) = (node.value, node.condition)


code_apply(arg_exprs...) = :(($arg_exprs[1])($arg_exprs[2:end]...))

code_node(node::VarNode) = node.name
code_node(node::AtomNode) = quot(node.value)
code_node(::FuncNode, arg_exprs...) = code_apply(arg_exprs...)


getkey(node::SourceNode) = node
getkey(node::FuncNode) = (FuncNode, node.args)
getkey(node::GateNode) = (GateNode, node.value, node.condition)


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
