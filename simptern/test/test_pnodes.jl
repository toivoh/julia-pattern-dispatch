
require("simptern/pnode.jl")
require("simptern/code_match.jl")
require("pretty/pretty.jl")


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
sink2 = make_net(arg)[1]

nodes3 = make_net(arg)
nodes4 = make_net(arg)

pprintln(code_match(sink))

println()
@show is(sink, sink2)
@show [is(n1,n2) for (n1,n2) in zip(nodes3,nodes4)]
