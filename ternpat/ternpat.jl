
load("pattern/req.jl")
req("ternpat/utils.jl")
req("pretty/pretty.jl")


egal(x,y) = is(x,y)
egal{T<:Number}(x::T, y::T) = isequal(x, y)
egal{T<:Tuple}(xs::T, ys::T) = all({egal(x,y) for (x,y) in zip(xs,ys)})


# -- PNode hierarchy ----------------------------------------------------------

abstract PNode
abstract   ExecNode   <: PNode      # Nodes that execute but produce no value
abstract   ResultNode <: PNode      # Nodes that produce a value
abstract     ValueNode  <: ResultNode # Nodes without strict order dependencies
abstract       SourceNode     <: ValueNode  # Leaf nodes


## Guard condition: predicate evaluates false ==> pattern does not match
type Guard <: ExecNode
    predicate::ResultNode
end
# subs_links(s, node::Guard) = Guard(s[node.predicate])

# egal(x::Guard, y::Guard) = egal(x.predicate, y.predicate)
# isequal(x::Guard, y::Guard) = egal(x, y)
# hash(x::Guard) = hash(x.predicate)


## DepNode: Collection of order dependencies
#typealias DependableNode Union(ExecNode, FuncNode)
type DepNode <: ExecNode
    deps::Set{PNode}
end
function DepNode(deps::PNode...)
    s = Set{PNode}()
    for node in deps
        if !isa(node, SourceNode)
            add(s, node)
        end
    end
    DepNode(s)
end

dep(node::DepNode) = node
dep(args::Tuple) = dep(args...)
dep(args...) = DepNode(args...)


## FuncNode: Node that evaluates using a function call, after deps executed
type FuncNode <: ResultNode
    deps::DepNode
    args::(ValueNode...)  # until there are immutable arrays
end
function FuncNode(deps, args) 
    FuncNode(dep(deps), convert((ValueNode...), tuple(args...)))
end
# subs_links(s, node::FuncNode) = FuncNode(s[node.deps], s[node.args])

# # todo: get this into upstream if I need it?
# function isequal{T}(xs::Set{T}, ys::Set{T})
#     (length(xs)==length(ys)) && allp(x->has(ys,x), xs)
# end

# # todo: don't use isequal in egal!
# egal(x::FuncNode, y::FuncNode) = isequal(x.deps,y.deps) && egal(x.args,y.args)

## MeetNode: equivalence class of nodes that must give the same value on match
type MeetNode <: ValueNode
    primary_factor::ResultNode
    factors::Set{ResultNode}  # mutable    
end
function MeetNode(primary_factor::ResultNode, factors::ResultNode...) 
    MeetNode(primary_factor, Set{ResultNode}(primary_factor, factors...))
end
# function subs_links(s, node::MeetNode) 
#     #  subs_links must return the same MeetNode, since it can have back edges
#     node.primary_factor = s[node.primary_factor]
#     node.factors = s[node.factors]
#     node
# end

## VarNode: Read from a named variable
type VarNode <: SourceNode
    name::Symbol
end
## AtomNode: Inline constant value
type AtomNode{T} <: SourceNode
    value::T
end
subs_links(s, node::SourceNode) = node

egal(x::AtomNode, y::AtomNode) = egal(x.value, y.value)
isequal(x::AtomNode, y::AtomNode) = egal(x, y)
hash(x::AtomNode) = hash(x.value)


## PNode methods

# get_deps: nodes that should be evaluated before this one
# get_args: nodes whose value this one depends on
# get_links: all the nodes that this node cares about

get_deps(node::Guard) = (node.predicate,)
get_args(node::Guard) = (node.predicate,)
get_links(node::Guard) = (node.predicate,)

get_deps(node::DepNode) = node.deps
get_args(node::DepNode) = ()
get_links(node::DepNode) = node.deps

# get_deps/get_args: Don't really apply to MeetNodes?
get_links(node::MeetNode) = node.factors

get_deps(node::FuncNode) = (node.deps,)
get_args(node::FuncNode) = node.args
get_links(node::FuncNode) = {node.deps..., node.args...}

get_deps(::PNode)  = ()
get_args(::SourceNode) = ()
get_links(::SourceNode) = ()


# getkey(node::FuncNode) = (FuncNode, node.args::Tuple)  # exclude deps from key
# getkey(node::PNode)    = node


code_node(node::VarNode) = node.name
code_node(node::AtomNode) = quot(node.value)
code_node(::FuncNode, arg_exprs...) = :(($arg_exprs[1])($arg_exprs[2:end]...))

#show(io::IO, g::Guard) = print(io, enclose("Guard(", g.predicate, ")"))
show(io::IO, node::MeetNode) = print(io, "MeetNode(...)")
function show(io::IO, node::FuncNode)
    print(io, enclose("FuncNode(", node.deps, ", ", node.args, ")"))
end


# -- Helpers ------------------------------------------------------------------

convert(::Type{ValueNode}, x::FuncNode) = MeetNode(x)
convert(::Type{ValueNode}, x::PNode)    = x::ValueNode
convert(::Type{ValueNode}, x)           = AtomNode(x)

convert(::Type{ResultNode}, x::PNode)   = x::ResultNode
convert(::Type{ResultNode}, x)          = AtomNode(x)


typeguard(x, T) = Guard(FuncNode(dep(), (isa, x, T)))

egaldep(x::ResultNode, y::ResultNode) = dep(x, y, MeetNode(x,y))
egaldep(args...) = egaldep(convert((ResultNode...), args)...)

macro ternpat(args...)
    code_ternpat(args...)
end
function code_ternpat(arg)
    g,call = is_expr(arg,:block) ? (arg.args[1:end-1],arg.args[end]) : ({},arg)
    @expect is_expr(call, :call)
    quote
        FuncNode(dep($g...), tuple($call.args...))
    end
end
