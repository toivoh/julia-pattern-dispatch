
load("pattern/req.jl")
req("circular/nodepatterns.jl")


type RPContext
    vars::Dict{Symbol,PVar}
    s::Subs
    RPContext() = new(Dict{Symbol,PVar}(), Subs())
end
getvar(c::RPContext, name::Symbol) = (@setdefault c.vars[name] = PVar(name))


function recode_patex(ex)
    c = RPContext()
    recode_patex(c, ex)
end

recode_patex(c::RPContext, xs::Vector) = {recode_patex(c,x) for x in xs}

recode_patex(c::RPContext, ex) = quot(Atom(ex))  # literal, hopefully?
recode_patex(c::RPContext, ex::Symbol) = quot(getvar(c, ex))

function recode_patex(c::RPContext, ex::Expr)
    head, args = ex.head, ex.args
    nargs = length(args)
    if head == doublecolon
        error("recode_patex: :: unimplemented")
    elseif head == :tuple
        recoded_args = recode_patex(c,args)
        return :(as_pnode(TuplePattern(tuple($recoded_args...))))
    elseif (head == :call) && (args[1] == :~) && (nargs == 3)
        recoded_args = recode_patex(c,args)
        return :(unite(($quot(c.s)), ($recoded_args[2]),($recoded_args[3])))
    else
        return expr(head, recode_patex(c,args))
    end    
end


macro pattern(args...)
    code_pattern(args...)
end

function code_pattern(args...)
    c = RPContext()
    args = recode_patex(c, {args...})
    if length(args) == 1
        #args[1]
        :(make_node_tree(($quot(c.s)), args[1]))
    else
        :(make_node_tree(($quot(c.s)), tuple($args...)))
    end
end
