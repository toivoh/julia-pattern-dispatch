
load("pattern/req.jl")
req("pattern/utils.jl")
req("pattern/core.jl")


# -- aspattern ----------------------------------------------------------------

aspattern(p::Pattern) = p
aspattern(p::PatternVar) = pvar(p)
function aspattern(p)
    if isatom(p); Atom(p)
    else; error("unimplemented!")
    end
end


# -- recode_pattern_ex --------------------------------------------------------

type RPContext
    vars::Dict{Symbol,Symbol}  # variable name ==> temp var name
    RPContext() = new(Dict{Symbol,Symbol}())
end

function getvar(c::RPContext, name::Symbol)
    has(c.vars, name) ? c.vars[name] : ( c.vars[name] = gensym(string(name)) )
end
function code_create_pvars(c::RPContext)
    { :( ($tmpname)=pvar($quotevalue(name)) ) for (name, tmpname) in c.vars }
end

recode_pattern_ex(ex) = recode_pattern_ex(ex, false)
function recode_pattern_ex(ex, raw::Bool)
    rpc = RPContext()
    pattern_ex = recode_pattern_ex(rpc, ex)
    pvar_defs  = code_create_pvars(rpc)
    if raw
      :( let ($pvar_defs...)
          ($pattern_ex)
        end)
    else
      :( let ($pvar_defs...)
          aspattern($pattern_ex)
        end)
    end    
end

function recode_pattern_ex(c::RPContext, ex::Expr)
    head, args = ex.head, ex.args
    nargs = length(args)
    if head == doublecolon
        @expect nargs==2
        arg = recode_pattern_ex(c, args[1])
        return :( restrict(($arg), ($args[2])) )
    elseif contains([:call, :ref, :curly], head)
        if (head==:call) && (args[1]==:staticvalue)
            @expect nargs==2
            return eval(args[2])
        else
            return expr(head, args[1], 
                       {recode_pattern_ex(c,arg) for arg in ex.args[2:end]}...)
        end
    else
        return expr(head, {recode_pattern_ex(c,arg) for arg in ex.args})
    end
end
recode_pattern_ex(c::RPContext, sym::Symbol) = getvar(c, sym)
recode_pattern_ex(c::RPContext, ex) = ex # other terminals
