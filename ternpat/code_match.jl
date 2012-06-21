
load("pattern/req.jl")
req("ternpat/ternpat.jl")

type MatchCode
    results::Dict{PNode,Any}
    eq_results::Dict{PNode}{Any}
    code::Vector

    MatchCode() = new(Dict{PNode,Any}(), Dict{PNode,Any}(), {})
end
function get_result(c::MatchCode, node::PNode)
    if has(c.results, node)
        return c.results[node]
    else
        ex = c.results[node] = code_match(c, node)
        emit_eqguard(c, node)
        ex
    end
end

function emit_eqguard(c::MatchCode, node::PNode)
    if !(has(c.results, node) && has(c.eq_results, node)); return; end
    ex, eq_ex = c.results[node], c.eq_results[node]
    if !is(eq_ex, ex)
        code_guard(c, :(($quot(egal))(($eq_ex), ($ex))))
    end
end

function code_match(sink::PNode)
    c = MatchCode()
    get_result(c, sink)
    expr(:block, c.code)
end

#code_match(c::MatchCode, node::MeetNode) = get_result(c, node.primary_factor)
function code_match(c::MatchCode, node::MeetNode) 
    ex = get_result(c, node.primary_factor)
    for factor in node.factors
        if !has(c.eq_results, factor)
            c.eq_results[factor] = ex
            emit_eqguard(c, factor)
        end
    end
    ex
end
function code_match(c::MatchCode, node::PNode) # PNode except MeetNode
    for dep in get_deps(node); get_result(c, dep); end  # evaluate deps first
    arg_exprs = {get_result(c, arg) for arg in get_args(node)}
    code_node(c, node, arg_exprs...)
end

code_node(c::MatchCode, ::Guard, pred_ex) = code_guard(c, pred_ex)
function code_guard(c::MatchCode, pred_ex) 
    if pred_ex == quot(true); return; end
    push(c.code, :( 
        if !($pred_ex)
            return false
        end
    ))
    nothing
end
function code_node(c::MatchCode, node::ResultNode, arg_exprs...)
    code_node(node, arg_exprs...)
end

code_node(c::MatchCode, ::DepNode) = nothing
