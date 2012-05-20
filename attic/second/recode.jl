
load("utils/req.jl")
req("utils/utils.jl")
req("patterns.jl")

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

function recode_pattern_ex(ex)
    rpc = RPContext()
    pattern_ex = recode_pattern_ex(rpc, ex)
    pvar_defs  = code_create_pvars(rpc)
    :( let ($pvar_defs...)
        ($pattern_ex)
    end )    
end

function recode_pattern_ex(c::RPContext, ex::Expr)
    head, args = ex.head, ex.args
    nargs = length(args)
    if head == doublecolon
        @expect nargs==2
        arg = recode_pattern_ex(c, args[1])
#        return :( restrict(($arg), ($args[2])) )
        return :( ($quotevalue(restrict))(($arg), ($args[2])) )
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
