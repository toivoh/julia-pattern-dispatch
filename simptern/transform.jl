
load("pattern/req.jl")
req("simptern/pnode.jl")


has_any(s, args...) = anyp(arg->has(s,arg), args)

typealias ResDict Dict{Any,PNode}
type EndoMap <: Subs
    memo::Dict{PNode,PNode}
    results::ResDict

    EndoMap() = new(Dict{PNode,PNode}(), ResDict())
end

function subs_node(m::EndoMap, node::PNode)    
    if !allp(link->(egal(link, m[link])), get_links(node))
        subs_links(m, node)
    else
        node
    end
end

ref(m::EndoMap, nodes::Vector{PNode}) = PNode[m[tuple(nodes...)]...]

function ref(m::EndoMap, node::PNode)
    if has(m.memo, node);  return m.memo[node];  end

    snode = subs_node(m, node)
    key = getkey(snode)
 
   if has(m.results, key)
        result = m.results[key]
    else
        result = m.results[key] = snode
    end    

    m.memo[node] = result
end
