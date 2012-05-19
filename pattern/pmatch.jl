

load("pattern/req.jl")
req("pattern/utils.jl")
req("pattern/core.jl")
req("pattern/recode.jl")


# == code_pmatch: patterns --> matching code ==================================

type PMContext
    assigned_vars::Set{PatternVar}  # the vars that have been assigned so far
    nomatch_ex    # expr to be returned if match fails
    code::Vector  # generated exprs

    PMContext(nomatch_ex) = new(Set{PatternVar}(), nomatch_ex, {})
    PMContext() = PMContext(:false)
end
emit(c::PMContext, ex) = (push(c.code,ex); nothing)
emit(c::PMContext, exprs...) = (append!(c.code, {exprs...}); nothing)
get_varnames(c::PMContext) = {p.name for p in c.assigned_vars}

function code_iffalse_ret(c::PMContext, pred)
    :(if !($pred)
        return ($c.nomatch_ex)
    end)
end


## code_pmatch: create pattern matching code from pattern ##
code_pmatch(p,xname::Symbol) = code_pmatch(aspattern(p),xname)
function code_pmatch(p::Pattern,xname::Symbol)
    c = PMContext()
    code_pmatch(c, p,xname)
    expr(:block, c.code)
end

code_pmatch(::PMContext, ::NonePattern,::Symbol) = error("never matches!")
function code_pmatch(c::PMContext, p::PVar,xname::Symbol)
    if has(c.assigned_vars, p.var)
        emit(c, code_iffalse_ret(c, 
            :( ($code_contains(p.dom,xname)) &&
               isequal_atoms(($p.var.name),($xname))
        )))
    else
        emit(c, 
            code_iffalse_ret(c, code_contains(p.dom,xname)),
            :( ($p.var.name) = ($xname) )
        )
        add(c.assigned_vars, p.var)
    end
end
function code_pmatch(c::PMContext, p::Composite,xname::Symbol)
    error("unimplemented!")
end
function code_pmatch(c::PMContext, p::Atom,xname::Symbol)
    emit(c, code_iffalse_ret(c, :(
        isequal_atoms(($quotevalue(p.value)),($xname))
    )))
end

