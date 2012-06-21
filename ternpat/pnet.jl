
load("pattern/req.jl")
req("ternpat/ternpat.jl")


has_any(s, args...) = anyp(arg->has(s,arg), args)


# -- Subs ---------------------------------------------------------------------

typealias SubsDict Dict{PNode,PNode}
type Subs
    dict::SubsDict
    Subs() = new(SubsDict())
end

has(s::Subs, node::PNode) = has(s.dict, node)


function ref(s::Subs, node::PNode) 
    if has(s.dict, node)
        s.dict[node] = s[s.dict[node]]
    else
        node
    end
end

ref(s::Subs, nodes::(PNode...)) = map(node->s[node], nodes)
ref{T<:PNode}(s::Subs, nodes::Set{T}) = Set{T}(s[tuple(nodes...)]...)

function subs_node(s::Subs, node::PNode)
    if has(s, node)
        s[node]
    elseif has_any(s.dict, get_links(node)...)
        s[node] = subs_links(s, node)
    else
        node
    end
end

function assign(s::Subs, new_node::PNode, old_node::PNode)
    @expect !has(s.dict, old_node)
    if egal(old_node, new_node); return; end
    @expect !has(s.dict, new_node)
    s.dict[old_node] = new_node
    new_node
end


# -- PNet ---------------------------------------------------------------------

typealias ResDict Dict{Any,PNode}

type PNet
    subs::Subs
    results::ResDict
    nodes::Set{PNode}  # do I want this one?

    PNet() = new(Subs(), ResDict(), Set{PNode}())
end

function add(net::PNet, node::PNode)
    if has(net.nodes, node); return; end
    add(net.nodes, node)

    # really go through the back edges too?
    for link in get_links(node)
        add(net, link)
    end

    node = subs_node(net.subs, node)

    keys = getkeys(node)    
    while true
        local k, collision = false
        for k in keys; if has(net.results, k)
            collision = true
            break
        end; end        
        if !collision; break; end

        node0 = net.results[k] # todo: look up node0 up in subs?

        keys0 = getkeys(node0)
        for k0 in keys0;  del(net.results, k0);  end
        
        node = unify_nodes(net, node0, node)

        keys = getkeys(node)
    end

    # no collisions left: store the result at results[keys...]
    for k in keys;  net.results[k] = node;  end
end

function unify_nodes(net::PNet, x::PNode, y::PNode)
    if egal(x, y)
        return x
    else
        global ux=x, uy=y
        global uz=unify_nodes(x, y)
        net.subs[x] = uz
        net.subs[y] = uz
        return uz
#        return net.subs[x] = net.subs[y] = unify_nodes(x, y)
    end
end


function unify_nodes(x::FuncNode, y::FuncNode)
    x  # todo: combine the deps?
end

function unify_nodes(x::MeetNode, y::MeetNode)
    # todo: determine which source_factor to use
    MeetNode(x.primary_factor, x.factors..., y.factors...)
end


# default, supposing T<:PNode never aliases nodes with different meanings onto 
# the same key:
unify_nodes{T<:PNode}(x::T, y::T) = x 
