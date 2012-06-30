
load("pattern/req.jl")
req("simptern/pnode.jl")
req("simptern/code_match.jl")
req("simptern/transform.jl")
req("pretty/pretty.jl")

function make_net(arg::PNode)
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

    sink, gvector, arg_v, len, glen2, arg_v2, e1, e2, ge1, ge2
end

arg = VarNode(:arg)

sink, gvector, arg_v, len, glen2, arg_v2, e1, e2, ge1, ge2 = make_net(arg)

m = EndoMap()
msink = m[sink]
# show(sink2)

gv = isanode(arg, Vector)
@assert egal(m[gv], gvector)

sink2 = make_net(arg)[1]

@assert !egal(sink, sink2)
@assert egal(sink, m[sink2])
