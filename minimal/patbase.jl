

const is_linenumber = Base.is_linenumber
const is_quoted     = Base.is_quoted
const unquoted      = Base.unquoted

require("utils.jl")

egal(x,y) = is(x,y)

# ---- nodes ------------------------------------------------------------------

abstract Node
abstract   Source <: Node

type Arg      <: Source; end
type Atom     <: Source; value;        end
#type Variable <: Node; name::Symbol;   end
type Guard    <: Node; pred::Node;     end
type NodeSet  <: Node; set::Set{Node}; end
type Assign   <: Node; dest::Symbol; value::Node     end
type Gate     <: Node; value::Node;  guard::Node     end 
type Apply    <: Node; f::Node;      args::(Node...) end

#typealias Leaf Union(Source, Variable)
typealias Leaf Source

get_links(node::Leaf)    = ()
get_links(node::Guard)   = (node.pred,)
get_links(node::NodeSet) = node.set
get_links(node::Assign)  = (node.value,)
get_links(node::Gate)    = (node.value, node.guard)
get_links(node::Apply)   = {node.f, node.args...}


const arg_symbol = gensym("arg")

code_match(c, node::Arg)      = arg_symbol
code_match(c, node::Atom)     = quot(node.value)
#code_match(c, node::Variable) = node.name
code_match(c, node::Guard)    = emit_guard(c, c[node.pred])
code_match(c, node::NodeSet)  = Set({c[member] for member in node.set})
code_match(c, node::Assign)   = emit_assign(c, node.dest, c[node.value])
code_match(c, node::Gate)     = (c[node.guard]; c[node.value])
function code_match(c, node::Apply)
    expr(:call, c[node.f], {c[arg] for arg in node.args}...)
end


atom(value)            = Atom(value)
#variable(name::Symbol) = Variable(name)

guard(pred::Node) = Guard(pred)
nodeset(nodes::Node...) = NodeSet(Set{Node}(nodes...))
d_apply(f::Function, args...) = Apply(atom(f), args)
assignvar(dest::Symbol, value::Node) = Assign(dest, value)
gate(value::Node, guard::Node) = Gate(value, guard)

# ---- code_match -------------------------------------------------------------

type MatchCode
    results::Dict{Node,Any}
    assigned::Set{Symbol}
    code::Vector

    MatchCode() = new(Dict{Node,Any}(), Set{Symbol}(), {})
end
emit(c::MatchCode, ex) = (push(c.code, ex); nothing)
function emit_guard(c::MatchCode, pred_ex)
    emit(c, :(
        if !($pred_ex)
            return (false, nothing)
        end
    ))
end
function emit_assign(c::MatchCode, dest::Symbol, value)
    if has(c.assigned, dest) 
        emit_guard(c, :( egal(($dest), ($value)) ))
    else
        add(c.assigned, dest)
        emit(c, :( ($dest) = ($value) ))
    end
end

abstract Usage
type Used   <: Usage; end
type Reused <: Usage; end

mark_reused(c::MatchCode, node::Leaf) = nothing
function mark_reused(c::MatchCode, node::Node)
    if has(c.results, node) c.results[node] = Reused(); return end
    c.results[node] = Used()
    for link in get_links(node) mark_reused(c, link) end
end

function ref(c::MatchCode, node::Node)
    r = get(c.results, node, Used())
    if !isa(r, Usage) return r; end
    result = code_match(c, node)
    if is(r, Reused()) &&
        !(isa(result, Symbol) || is_quoted(result) || is(result, nothing))
        temp = gensym("temp")
        emit_assign(c, temp, result)
        result = temp
    end
    c.results[node] = result
end

function code_match(node::Node)
    c = MatchCode()
    mark_reused(c, node)
    c[node]
    c.code
#    expr(:block, c.code)
end

# ---- pattern --> DAG --------------------------------------------------------

atompat(value)       = arg->guard(d_apply(egal, arg, atom(value)))
#varpat(name::Symbol) = arg->guard(d_apply(egal, arg, variable(name)))
varpat(name::Symbol) = arg->assignvar(name, arg)
typepat(T)           = arg->guard(d_apply(isa,  arg, atom(T)))
meetpat(ps...)       = arg->nodeset({p(arg) for p in ps}...)
tuplepat(ps...)      = arg->seqnet(arg, Tuple,  ps...)
vectorpat(ps...)     = arg->seqnet(arg, Vector, ps...)

function seqnet(arg, T, ps...)
    n = length(ps)
    arg = gate(arg, typepat(T)(arg))

    lguard = atompat(length(ps))(d_apply(length, arg))
    if n == 0; return lguard; end
    arg = gate(arg, lguard)

    nodeset({p(d_apply(ref, arg, atom(k))) for (p, k) in enumerate(ps)}...)
end

# ---- recode -----------------------------------------------------------------

recode_typepat(Tname) = :(typepat($esc(Tname)))

recode(vars::Set{Symbol}, exs::Vector) = {recode(vars, ex) for ex in exs}
function recode(vars::Set{Symbol}, ex::Expr)
    head, args = ex.head, ex.args
    nargs = length(args)
    if head === doublecolon
        if nargs == 1
            return recode_typepat(args[1])
        else
            argpat = recode(vars, args[1])
            tpat   = recode_typepat(args[2])
            return :(meetpat(($argpat), ($tpat)))
        end
    elseif head === :tuple
        return :(tuplepat($recode(vars, args)...))
    elseif head === :cell1d
        return :(vectorpat($recode(vars, args)...))
    elseif head === :call
        if nargs == 3 && args[1] == :(~)
            return :(meetpat($recode(vars, args[2:end])...))
        end
    end
    error("Unimplemented!")
end
recode(vars::Set{Symbol}, ex::Symbol) = (add(vars, ex); :(varpat($quot(ex))))
recode(vars::Set{Symbol}, ex) = :(atompat($quot(ex)))  # literal, hopefully

recode(ex) = (vars=Set{Symbol}(); p=recode(vars, ex); (Symbol[vars...], p))

type PatternMethod
    sig::Node
    args::Vector{Symbol}
    body::Function
end

function recode_fdef(fdef)
    fname, signature, body = split_fdef3(fdef)

    vars, pattern = recode(expr(:tuple, signature))
    bodyfun = expr(:(->), expr(:tuple, vars...), body)

    @show bodyfun
    @show signature
    @show vars
    @show pattern
    
    fname, :(PatternMethod(($pattern)(Arg()), ($quot(vars)), ($bodyfun)))
end
