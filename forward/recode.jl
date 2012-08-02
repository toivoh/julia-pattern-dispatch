
load("pattern/req.jl")
req("pattern/nodepatterns.jl")

typealias RPCVars Dict{Symbol,PVar}
type RPContext
    vars::RPCVars
    s::Subs
    RPContext(vars::RPCVars) = new(vars, Subs())
end
RPContext() = RPContext(RPCVars())

getvar(c::RPContext, name::Symbol) = (@setdefault c.vars[name] = PVar(name))


recode_patex(ex) = recode_patex(RPCVars(), ex)
function recode_patex(vars::RPCVars, ex)
    c = RPContext(vars)
    rex = recode_patex(c, ex)
    :(normalized_pattern(($quot(c.s)), ($rex)))
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
    elseif contains([:call, :ref, :curly], head)
        if head == :call
            if args[1] == :pat
                @expect nargs==2
                return args[2]
            end
            if args[1] == :atom
                @expect nargs==2
                return :(Atom($args[2]))
            end
        end

        recoded_args = {args[1], recode_patex(c,args[2:end])...}
        return expr(head, recode_patex(c,args))
    else
        return expr(head, recode_patex(c,args))
    end    
end


macro qpat(args...)
    code_pattern(args...)
end

function code_pattern(args...)
    c = RPContext()
    args = {recode_patex(c.vars, arg) for arg in args}
    if length(args) == 1
        args[1]
    else
        :(tuple($args...))
    end
end