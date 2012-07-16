
require("simptern/pnode.jl")


type Unorder; end
typealias UnorderMap EndoMap{Unorder}

evalkernel(m::UnorderMap, node::GateNode) = node.value
evalkernel(m::UnorderMap, node::PNode) = node


unorder(node::PNode) = UnorderMap()[node]
unorder_guards(node::PNode) = get_guards(unorder(node))

ternpat_eq(n::PNode, m::PNode) = iseqset( map(unorder_guards, (n, m))...)
ternpat_ge(n::PNode, m::PNode) = issubset(map(unorder_guards, (n, m))...)
ternpat_le(n::PNode, m::PNode) = ternpat_ge(m::PNode, n::PNode)


iseqset(s::Set, t::Set)    = (length(s)==length(t)) && issubset(s,t)
issubset(s::Set, t::Set)   = allp(x->has(t,x), s)
issuperset(s::Set, t::Set) = issubset(t, s)
