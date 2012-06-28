
load("pattern/req.jl")
req("simptern/pnode.jl")

quot(ex) = expr(:quote, ex)

is_true_expr(ex) = (ex == :true) || (ex == quot(true))


type MatchCode
    guards::Set{PNode}
    results::Dict{PNode,Any}
    code::Vector

    MatchCode(guards::Set{PNode}) = new(guards, Dict{PNode,Any}(), {})   
end

function get_result(c::MatchCode, node::PNode)
    if has(c.results, node); return c.results[node]
    else;                    return c.results[node] = code_match(c, node)
    end
end

function emit_guard(c::MatchCode, pred_ex) 
    if is_true_expr(pred_ex); return; end
    push(c.code, :( 
        if !($pred_ex)
            return false
        end
    ))
    nothing
end


function code_match(sink::PNode)
    guards = get_guards(sink)
    c = MatchCode(guards)
    get_result(c, sink)
    expr(:block, c.code)
end

function code_match(c::MatchCode, node::GateNode)
    cond_ex = get_result(c, node.condition)
    @assert is_true_expr(cond_ex)
    get_result(c, node.value)
end

function code_match(c::MatchCode, node::PNode)
    args = {get_result(c, arg) for arg in get_args(node)}
    ex = code_node(node, args...)
    
    if has(c.guards, node)
        emit_guard(c, ex)
        ex = quot(true)
    end
    ex
end

