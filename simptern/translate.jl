
require("simptern/pnode.jl")

type ArgPat
    f::Function
    restargs::Tuple
    ArgPat(f::Function, restargs...) = new(f, restargs)
end
makenet(arg::PNode, p::ArgPat) = p.f(arg, p.restargs...)

atom(value::PNode) = ArgPat(atom, value)
pvar(name::Symbol) = ArgPat(pvar, name)
typeguard(T_node::PNode) = ArgPat(typeguard, T_node)
meetpats(ps::ArgPat...) = ArgPat(meetpats, ps...)
tuplepat(ps::ArgPat...) = ArgPat(tuplepat, ps...)

atom(arg::PNode, value::PNode) = guard(egalnode(arg, value))
pvar(arg::PNode, name::Symbol) = bind(name, arg)
typeguard(arg::PNode, T_node::PNode) = guard(isanode(arg, T_node))

function meetpats(arg::PNode, ps::ArgPat...)
    meet({makenet(arg, p) for (p,k) in enumerate(ps)}...)
end

function tuplegate(arg::PNode, n::Int)
    gtuple = isanode(arg, Tuple)
    arg_t = GateNode(arg, gtuple)
    
    len = funcnode(length, arg_t)
    glen = egalnode(len, n)
    arg_tlen = GateNode(arg_t, glen)

    arg_tlen, guard(andnode(gtuple, glen))
end

function tuplepat(arg::PNode, ps::ArgPat...)
    targ, match = tuplegate(arg, length(ps))
    meet(match, {makenet(funcnode(ref, targ, k), p) for 
                 (p,k) in enumerate(ps)}...)
end
