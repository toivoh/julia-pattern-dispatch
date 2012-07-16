
require("simptern/pnode.jl")


# -- recode -------------------------------------------------------------------

recode_patex(xs::Vector) = {recode_patex(x) for x in xs}

recode_patex(ex) = quot(atom(ex))  # literal, hopefully?
recode_patex(ex::Symbol) = quot(pvar(ex))

function recode_patex(ex::Expr)
    head, args = ex.head, ex.args
    nargs = length(args)
    if head == doublecolon
        @assert 1 <= nargs <= 2
        if nargs==1
            return :(fixed_typeguard($args[1]))
        elseif nargs==2
            recoded_arg = recode_patex(args[1])
            :(meetpats(($recoded_arg),fixed_typeguard($args[2])))
        end 
    elseif head == :tuple
        recoded_args = recode_patex(args)
        return :(tuplepat($recoded_args...))
    elseif (head == :call) && (nargs >= 3) && (args[1] == :~) 
        recoded_args = recode_patex(args)
        return :(meetpats($recoded_args[2:end]...))
    elseif contains([:call, :ref, :curly], head)
        if head == :call
            if args[1] == :atom
                @expect nargs==2
                return :(atom($args[2]))
            end
        end
        recoded_args = {args[1], recode_patex(args[2:end])...}
        return expr(head, recoded_args)
    else
        return expr(head, recode_patex(args))
    end    
end


macro qpat(arg)
    recode_patex(arg)
end
macro qpats(args...)
    expr(:tuple, {recode_patex(arg) for arg in args})
end



# -- patterns -----------------------------------------------------------------

type ArgPat
    f::Function
    restargs::Tuple
    ArgPat(f::Function, restargs...) = new(f, restargs)
end
makenet(arg::PNode, p::ArgPat) = p.f(arg, p.restargs...)

fixed_typeguard(T) = typeguard(AtomNode(T))

atom(value) = ArgPat(atom, AtomNode(value))
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
