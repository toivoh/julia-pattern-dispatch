
load("pattern/req.jl")
req("tern/pnode.jl")


type MatchCode
    results::Dict{PNode,Any}
    code::Vector
    MatchCode() = new(Dict{PNode,Any}(), {})
end

function get_result(c::MatchCode, node::PNode)
    if has(c.results, node)
        return c.results[node]
    else
        return c.results[node] = code_match(c, node)        
    end
end


function code_match(sink::PNode)
    c = MatchCode()
    get_result(c, sink)
    expr(:block, c.code)
end

function code_match(c::MatchCode, node::PNode)
    args = {get_result(c, arg) for arg in get_args(node)}
    code_node(node, args...)
end
