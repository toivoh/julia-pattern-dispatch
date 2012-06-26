
load("pattern/req.jl")
req("tern/pnode.jl")
req("pretty/pretty.jl")


pnodeset(args...) = Set{PNode}(args...)
egalnode(args...) = EgalNode(pnodeset(args...))
andnode(args...) = AndNode(pnodeset(args...))

arg = VarNode(:arg)

p_vector = IsaNode(arg, AtomNode(Vector))
arg_v = GateNode(arg, p_vector)

len = FuncNode(AtomNode(length), arg_v)
p_len2 = egalnode(len, AtomNode(2))
arg_v2 = GateNode(arg_v, p_len2)

e1 = FuncNode(AtomNode(ref), arg_v2, AtomNode(1))
pe1 = egalnode(e1, AtomNode(1))

e2 = FuncNode(AtomNode(ref), arg_v2, AtomNode(2))
pe2 = egalnode(e2, arg)

sink = andnode(p_vector, p_len2, pe1, pe2)
