
load("pattern/req.jl")
req("ternpat/ternpat.jl")

type MatchCode
    results::Dict{PNode,Any}
    code::Vector

    MatchCode() = new(Dict{PNode,Any}(), {})
end

function get_result(c::MatchCode, node::PNode)
    @setdefault c.results[node] = code_match(c, node)
end

function code_match(sink::PNode)
    c = MatchCode()
    code_match(c, sink)
    expr(:block, c.code)
end

code_match(c::MatchCode, node::MeetNode) = get_result(c, node.source_factor)
function code_match(c::MatchCode, node::PNode) 
    for dep in get_deps(node); get_result(c, dep); end  # evaluate guards
    arg_exprs = {get_result(c, arg) for arg in get_args(node)}
    code_node(c, node, arg_exprs...)
end

function code_node(c::MatchCode, ::Guard, pred_ex)
    if pred_ex == quot(true); return; end
    push(c.code, :( 
        if !($pred_ex)
            return false
        end
    ))
    nothing
end
function code_node(c::MatchCode, node::ValNode, arg_exprs...)
    code_node(node, arg_exprs...)
end
