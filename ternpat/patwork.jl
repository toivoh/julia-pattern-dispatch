
load("pattern/req.jl")
req("ternpat/ternpat.jl")

type PNodeProps
    eqclass::PNode
    fwdeps::Set{PNode}
end

typealias SubsDict Dict{PNode,PNode}
typealias NodesDict Dict{Any,PNode}
typealias PropsDict Dict{PNode,PNodeProps}

type PGraph
    subs::SubsDict
    nodes::NodesDict
    props::PropsDict

    PGraph() = new(SubsDict(), NodesDict(), PropsDict())
end

function subs(g::PGraph, node::PNode)
    while has(g.subs, node)
        node = g.subs[node]  # todo: save the result to all of these?
    end

    node = subs_deps(g, node)
    
    g.subs[node] = node
end

function add(g::PGraph, node::PNode)
    node = subs(g, node)  # brings node up to date using g.subs

    if has(g.nodes, node); return; end
    g.props[node] = PNodeProps(node, Set{PNode}())

    key = getkey(node)
    if has(g.nodes, key)
        g.nodes[key] = unite(g, g.nodes[key],node)
    else
        g.nodes[key] = node
    end
end