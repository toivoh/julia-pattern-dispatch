
load("pattern/req.jl")
req("ternpat/ternpat.jl")

typealias SubsDict Dict{PNode,PNode}
type Subs
    dict::SubsDict
    Subs(args...) = new(SubsDict(args...))
end

has_any(s, items) = anyp(item->has(s,item), items)

has(s::Subs, node::PNode) = has(s.dict, node)

ref(s::Subs, node::PNode) = get(s.dict, node, node)
ref(s::Subs, nodes::(PNode...)) = map(node->s[node], nodes)
ref{T<:PNode}(s::Subs, nodes::Set{T}) = Set{T}(s[tuple(nodes...)]...)

subs_node(s::Subs, node::PNode) = has_any(s,get_links(node)) ? subs_links(s,node) : node

function assign(s::Subs, old_node::PNode, new_node::PNode)
    @expect !has(s.dict, old_node)
    if egal(old_node, new_node); return; end
    @expect !has(s.dict, new_node)
    s.dict[old_node] = new_node
    # todo: apply this subs to all nodes!
    new_node
end


typealias NodesDict Dict{Any,PNode}
type PGraph
    subs::Subs
    nodes::NodesDict  # key => PNode

    PGraph() = new(Subs(), NodesDict())
end
PGraph(nodes::PNode...) = (g=PGraph(); foreach(node->add(g,node), nodes); g)

function add(g::PGraph, node::PNode)
    node = subs_node(g.subs, node)
    if has(g.subs, node); return; end  # node has existed but was replaced
    if store_node(g, node)
        for link in get_links(node)
            add(g, link)
        end    
    end
end

function store_node(g::PGraph, node::PNode)
    key = getkey(node)    
    while has(g.nodes, key)
        node0 = g.nodes[key]
        new_node = unify(g, node0, node)

        if egal(new_node, node0); return false; end

        del(g.nodes, key)
        g.subs[node0] = g.subs[node] = new_node
        node = new_node

        key = getkey(node)
    end
    g.nodes[key] = node
    true
end

function unify(g::PGraph, x::PNode, y::PNode)
    if egal(x,y); return x; end
    error("Unimplemented: unify\n\tx=$x\n\ty=$y")
end
