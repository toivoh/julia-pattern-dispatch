
require("simptern/pnode.jl")
require("simptern/translate.jl")
require("simptern/code_match.jl")


global const pat_arg = gensym("arg")


# -- Pattern interface: -------------------------------------------------------

type Pattern
    arg::VarNode
    match::MatchNode
end

# i/f: recode_patex(ex) from translate.jl

pattern(arg::VarNode, p::ArgPat) = Pattern(arg, makenet(arg, p))
pattern(p::ArgPat) = pattern(VarNode(pat_arg), p)

get_argname(p::Pattern) = p.arg.name
get_varnames(p::Pattern) = get_symbol_names(p.match)
code_match(p::Pattern, args...) = code_match(p.match, args...)


function unify(p::Pattern, q::Pattern)
    @assert egal(p.arg, q.arg)
    Pattern(p.arg, meet(p.match, q.match))
end


## compare

nevermatches(p::Pattern) = is_false_expr(p.match.guard)

# strip symbol table, keep guard
# todo: unorder the DAG
feas(p::Pattern) = Pattern(p.arg, MatchNode(unorder(p.match.guard)))


function get_comp_guards(p::Pattern) 
    @assert isempty(p.match.symtable)
    get_guards(p.match.guard) 
end
function compare_guards(setrel::Function, p::Pattern, q::Pattern)
    @assert egal(p.arg, q.arg)
    setrel(get_comp_guards(p), get_comp_guards(q))
end

>=(p::Pattern, q::Pattern) = compare_guards(set_le, p, q)
==(p::Pattern, q::Pattern) = compare_guards(set_eq, p, q)
> (p::Pattern, q::Pattern) = compare_guards(set_lt, p, q)
<=(p::Pattern, q::Pattern) = q >= p
< (p::Pattern, q::Pattern) = q >  p


type Unorder; end
typealias UnorderMap EndoMap{Unorder}

evalkernel(m::UnorderMap, node::GateNode) = node.value
evalkernel(m::UnorderMap, node::PNode) = node

unorder(node::PNode) = UnorderMap()[node]

