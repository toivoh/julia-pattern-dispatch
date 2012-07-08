
load("pattern/req.jl")
req("simptern/pnode.jl")


type Unorder; end
typealias UnorderMap EndoMap{Unorder}

evalkernel(m::UnorderMap, node::GateNode) = node.value
evalkernel(m::UnorderMap, node::PNode) = node
