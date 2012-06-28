
load("pattern/req.jl")
req("simptern/pnode.jl")
req("simptern/code_match.jl")
req("pretty/pretty.jl")

arg = VarNode(:arg)

gvector = isanode(arg, Vector)
arg_v = GateNode(arg, gvector)

len = funcnode(length, arg_v)
glen2 = egalnode(len, 2)
arg_v2 = GateNode(arg_v, glen2)

e1 = funcnode(ref, arg_v2, 1)
e2 = funcnode(ref, arg_v2, 2)

ge1 = egalnode(e1, 1)
ge2 = isanode(e2, Int)

sink = andnode(gvector, glen2, ge1, ge2)

