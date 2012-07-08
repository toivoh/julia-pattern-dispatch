
require("simptern/immutable.jl")


abstract Subs

ref(s::Subs, args::Tuple) = map(x->s[x], args)
ref{T}(s::Subs, args::ImmVector{T}) = mapT(T, x->s[x], args)


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
end
FuncNode(args...) = FuncNode(ImmVector{PNode}(args...))
subs_links(s::Subs, node::FuncNode) = FuncNode(s[node.args])

@immutable type GateNode <: PNode
    value::PNode
    condition::PNode
end
subs_links(s::Subs, node::GateNode) = GateNode(s[node.value],s[node.condition])

type MatchNode <: PNode
    guard::PNode
    symtable::Dict{Symbol,PNode}

    MatchNode(guard::PNode, symtable::Dict) = new(guard, symtable)
end
MatchNode(g::PNode) = MatchNode(g, Dict{Symbol,PNode}())

get_symbol_names(node::MatchNode) = keys(node.symtable)


get_args(node::SourceNode) = ()
get_args(node::FuncNode) = node.args

get_links(node::SourceNode) = ()
get_links(node::FuncNode) = node.args
get_links(node::GateNode) = (node.value, node.condition)
get_links(node::MatchNode) = {node.guard, values(node.symtable)...}


code_apply(arg_exprs...) = :(($arg_exprs[1])($arg_exprs[2:end]...))

code_node(node::VarNode) = node.name
code_node(node::AtomNode) = quot(node.value)
code_node(::FuncNode, arg_exprs...) = code_apply(arg_exprs...)



function convert{Kd,Vd,Ks}(::Type{Dict{Kd,Vd}}, d::Dict{Ks})
    if !(Ks<:Kd)
        error("convert: can only widen key type for Dict")
    end
    dest = Dict{Kd,Vd}(length(d))
    for (k,v) in d
        dest[k] = v
    end
    dest
end


function meet(nodes::MatchNode...)
    @expect length(nodes) >= 1
    guard  = andnode({ node.guard            for node in nodes }...)
    symtable = merge({ node.symtable         for node in nodes }...)
    nsyms    =   sum({ length(node.symtable) for node in nodes })
    if length(symtable) != nsyms
        error("unimplemented: node unite")
    end
    MatchNode(guard, symtable)
end


# -- Helpers ------------------------------------------------------------------

const truenode = AtomNode(true)

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

# -- EndoMap ------------------------------------------------------------------

type EndoMap{T} <: Subs
    memo::Dict{PNode,PNode}
    data::T

    EndoMap(args...) = new(Dict{PNode,PNode}(), T(args...))
end

ref(m::EndoMap, node::PNode) = @setdefault m.memo[node] = evaluate(m, node)
evaluate(m::EndoMap, node::PNode) = evalkernel(m, subs_links(m, node))
