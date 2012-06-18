
load("pattern/req.jl")
req("ternpat/ternpat.jl")

type CodeOrder
    order::Vector{PNode}
    visited::Dict{PNode,Int}
    CodeOrder() = new(PNode[], Dict{PNode,Int}())
end

function order_pnodes(sink::PNode)
    c = CodeOrder()
    order_pnodes(c, sink)
    c.order
end

order_pnodes(c::CodeOrder, node::MeetNode) = order_pnodes(c, node, 1)
order_pnodes(c::CodeOrder, node::PNode)    = order_pnodes(c, node, 2)
function order_pnodes(c::CodeOrder, node::PNode, vthresh::Int)
#     orig_visited = get(c.visited, node, 0)
    c.visited[node] = 1  # mark visiting
    for arg in get_deps(node)
        if get(c.visited, arg, 0) < vthresh
            order_pnodes(c, arg)
        end
    end
#     if (c.visited[node] == 1) && (vthresh==2 || orig_visited==0) # leave node
    if c.visited[node] == 1  # leave node
        c.visited[node] = 2  # mark visited
        push(c.order, node)
    end
end

type MatchCode
    results::Dict{PNode,Any}
    code::Vector

    MatchCode() = new(Dict{PNode,Any}(), {})
end

function code_match(sink::PNode)
    order = order_pnodes(sink)    
    c = MatchCode()
    for node in order
        c.results[node] = code_match(c, node)
    end

    expr(:block, c.code)
end

function code_match(c::MatchCode, node::MeetNode)
    for factor in node.factors
        if has(c.results, factor)
            return c.results[factor]            
        end
    end
    error("no factors available for MeetNode!")
end
function code_match(c::MatchCode, node::PNode) 
    arg_exprs = {c.results[arg] for arg in get_args(node)}
    code_match(c, node, arg_exprs...)
end

function code_match(c::MatchCode, ::Guard, pred_ex)
    if pred_ex == quot(true); return; end
    push(c.code, :( 
        if !($pred_ex)
            return false
        end
    ))
    nothing
end
function code_match(c::MatchCode, node::ValNode)
    arg_exprs = {c.results[arg] for arg in get_args(node)}
    code_node(node, arg_exprs...)
end
