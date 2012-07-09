
require("simptern/pnode.jl")

is_true_expr(ex) = (ex == :true) || (ex == quot(true))


type MatchCode
    guards::Set{PNode}
    nodenames::Dict{PNode,Symbol}
    nomatch_ret  # expr to be returned if match fails

    fanout::Dict{PNode,Int}
    results::Dict{PNode,Any}
    code::Vector

    function MatchCode(guards::Set{PNode}, nodenames::Dict{PNode,Symbol}, nmr) 
        new(guards, nodenames, nmr, Dict{PNode,Int}(), Dict{PNode,Any}(), {})
    end
end

getname(c::MatchCode, node::PNode) = (@setdefault c.nodenames[node] = gensym())

is_simple_expr(ex::Expr) = is_true_expr(ex) || is_expr(ex, :quote)
is_simple_expr(ex) = true

function get_result(c::MatchCode, node::PNode)
    if has(c.results, node)
        return c.results[node]
    else
        ex = code_match(c, node)
        if (c.fanout[node] > 1) && (!is_simple_expr(ex))
            name = getname(c, node)
            push(c.code, :(($name)=($ex)))
            ex = name
        end
        return c.results[node] = ex
    end
end

function emit_guard(c::MatchCode, pred_ex) 
    if is_true_expr(pred_ex); return; end
    push(c.code, :( 
        if !($pred_ex)
            return ($c.nomatch_ret)
        end
    ))
    nothing
end

function mark_fanout(c::MatchCode, node::PNode)
    fanout = c.fanout[node] = get(c.fanout, node, 0) + 1
    if fanout > 1;  return;  end
    for arg in get_links(node)
        mark_fanout(c, arg)
    end
end

code_match(sink::PNode, args...) = code_match(MatchNode(sink), args...)
code_match(match::MatchNode) = code_match(match, quot(false))
function code_match(match::MatchNode, nomatch_ret)
    guards = get_guards(match.guard)

    nodenames = Dict{PNode,Symbol}()
    for (k,v) in match.symtable;  nodenames[v]=k;  end

    c = MatchCode(guards, nodenames, nomatch_ret)
    mark_fanout(c, match)
    get_result(c, match.guard)
    for (name,node) in match.symtable
        ex = get_result(c, node)
        if ex != name
            push(c.code, :(($name)=($ex)))
        end
    end
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

