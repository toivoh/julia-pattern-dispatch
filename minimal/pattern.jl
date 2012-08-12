

const is_linenumber = Base.is_linenumber
const unquoted      = Base.unquoted

require("utils.jl")

const egal = is

# ---- nodes ------------------------------------------------------------------

abstract Node

type Arg      <: Node; end
type Atom     <: Node; value;          end
type Variable <: Node; name::Symbol;   end
type Guard    <: Node; pred::Node;     end
type NodeSet  <: Node; set::Set{Node}; end
type Assign   <: Node; dest::Symbol; value::Node     end
type Gate     <: Node; value::Node;  guard::Node     end 
type Apply    <: Node; f::Node;      args::(Node...) end


const arg_symbol = gensym("arg")

code_match(c, node::Arg)      = arg_symbol
code_match(c, node::Atom)     = quot(node.value)
code_match(c, node::Variable) = node.name
code_match(c, node::Guard)    = emitguard(c, c[node.pred])
code_match(c, node::NodeSet)  = Set({c[member] for member in node.set})
code_match(c, node::Assign)   = emit(c, :( ($node.dest) = ($c[node.value]) ))
code_match(c, node::Gate)     = (c[node.guard]; c[node.value])
function code_match(c, node::Apply)
    expr(:call, c[node.f], {c[arg] for arg in node.args}...)
end


atom(value)            = Atom(value)
variable(name::Symbol) = Variable(name)

guard(pred::Node) = Guard(pred)
nodeset(nodes::Node...) = NodeSet(Set{Node}(nodes...))
d_apply(f::Function, args...) = Apply(atom(f), args)
assignvar(dest::Symbol, value::Node) = Assign(dest, value)
gate(value::Node, guard::Node) = Gate(value, guard)


# ---- code_match -------------------------------------------------------------

type MatchCode
    results::Dict{Node, Any}
    code::Vector

    MatchCode() = new(Dict{Node, Any}(), {})
end
emit(c::MatchCode, ex) = (push(c.code, ex); nothing)
function emitguard(c::MatchCode, pred_ex)
    emit(c, :(
        if !($pred_ex)
            return (false, nothing)
        end
    ))
end

function ref(c::MatchCode, node::Node)
    if has(c.results, node) return c.results[node] end
    c.results[node] = code_match(c, node)
end

function code_match(node::Node)
    c = MatchCode()
    c[node]
    c.code
#    expr(:block, c.code)
end


# ---- pattern --> DAG --------------------------------------------------------

atompat(value)       = arg->guard(d_apply(egal, arg, atom(value)))
#varpat(name::Symbol) = arg->guard(d_apply(egal, arg, variable(name)))
varpat(name::Symbol) = arg->assignvar(name, arg)
typepat(T)           = arg->guard(d_apply(isa,  arg, atom(T)))
meetpat(p, q)        = arg->nodeset(p(arg), q(arg))
tuplepat(ps...)      = arg->tuplenet(arg, ps...)

function tuplenet(arg, ps...)
    n = length(ps)
    arg = gate(arg, typepat(Tuple)(arg))

    lguard = atompat(length(ps))(d_apply(length, arg))
    if n == 0; return lguard; end
    arg = gate(arg, lguard)

    nodeset({p(d_apply(ref, arg, atom(k))) for (p, k) in enumerate(ps)}...)
end

# ---- recode -----------------------------------------------------------------

recode_typepat(Tname) = :(typepat($esc(Tname)))

function recode(ex::Expr)
    head, args = ex.head, ex.args
    nargs = length(args)
    if head === doublecolon
        if nargs == 1
            return recode_typepat(args[1])
        else
            argpat = recode(args[1])
            tpat   = recode_typepat(args[2])
            return :(meetpat(($argpat), ($tpat)))
        end
    elseif head === :tuple
        return :(tuplepat(${recode(arg) for arg in args}...))
    else
        error("Unimplemented!")
    end
end

recode(ex::Symbol) = :(varpat( $quot(ex)))
recode(ex)         = :(atompat($quot(ex)))  # literal, hopefully


# ---- @pattern ---------------------------------------------------------------

macro pattern(block)
    code_pattern(block)
end
function code_pattern(block)
    @expect is_expr(block, :block)
    
    methods = {}
    fnames  = {}
    for fdef in block.args
        if is_linenumber(fdef) continue end
        sig, body = split_fdef(fdef)
        fname, signature = sig.args[1], sig.args[2:end]

        sigpat = recode(expr(:tuple, signature))
        push(methods, :(($sigpat), ($quot(body))))

        push(fnames, fname)
        @show signature
        @show sigpat
    end

    fname = common_value(fnames)
    @show fname

    quote
        fdef = code_patterns(($quot(fname)), $methods...)
        eval(fdef)
    end
end

function code_patterns(fname::Symbol, methods...)
    body_code = {}
    for (p, body) in methods
        net = p(Arg())
        @show net

        code = code_match(net)
        @show(code)
        println()
        
        method_code = quote
            match, result = let
                ($code...)
                (true, ($body))
            end
            if match return result end
        end
        append!(body_code, method_code.args)
    end
    push(body_code, :( error($"no matching pattern for $fname") ))
#    @show expr(:block, body_code)

    fdef = :( ($fname)(($arg_symbol)...) = ($expr(:block, body_code)) )
    @show fdef
    fdef
end
