
require("simptern/pnode.jl")

abstract PNet
abstract   PartNet <: PNet
#abstract PPart

# type PartNet{T<:PPart} <: PNet
#     arg::PNode
#     part::T
#     match::MatchNode

#     PartNet(arg::PNode, part::T) = new(arg, part, make_net(arg, part))
# end

# type Atom <: PPart
#     value
# end

type AtomNet <: PartNet
    arg::PNode
    value::AtomNode
end
type PVarNet <: PartNet
    arg::PNode
    name::Symbol
end
type TypeGuardNet <: PartNet
    arg::PNode
    T_node::PNode
end

type TupleNet <: PartNet
    arg::PNode
    n::Int

    matchnode::MatchNode
    gated_arg::GateNode
end
function TupleNet(arg::PNode, n::Int) 
    assert(n) >= 0
    
    gtuple = isanode(net.arg, Tuple)
    arg_t = GateNode(net.arg, gtuple)
    
    len = funcnode(length, arg_t)
    glen = egalnode(len, net.n)
    arg_tlen = GateNode(arg_t, glen)
    
    TupleNet(arg, n, guard(andnode(gtuple, glen)), arg_tlen)
end

ref(net::TupleNet, node::PNode) = funcnode(ref, net.gated_arg, node)


matchnode(net::AtomNet) = guard(egalnode(net.arg, net.value))
matchnode(net::PVarNet) = bind(net.name, net.arg)
matchnode(net::TypeGuardNet) = guard(isanode(net.arg, net.T_node))
matchnode(net::TupleNet) = net.matchnode

type ArgPat
    f::Function
    restargs::Tuple
    ArgPat(f::Function, restargs...) = new(f, restargs)
end
to_net(p::ArgPat, arg::PNode) = p.f(arg, restargs...)

atom(value::AtomNode) = ArgPat(AtomNet, value)
pvar(name::Symbol)    = ArgPat(PVarNet, name)
typeguard(T_node::PNode) = ArgPat(TypeGuardNet, T_node)

tuplepat(ps::ArgPat) = ArgPat(tuplepat, ps...)

function tuplepat(arg::PNode, ps::ArgPat...)
    n = length(ps)
    net = TupleNet(arg, n)
    meet(net, {to_net(p, net[k]) for (p,k) in enumerate(ps)}...)
end


type CompositeNet <: PNet
    parts::Vector{PartNet}
    matchnode::MatchNode
end

function CompositeNet(parts::PartNet...)
    m = meet({matchnode(part) for part in parts}...)
    CompositeNet(PartNet[parts...], m)
end

matchnode(net::CompositeNet) = net.matchnode
