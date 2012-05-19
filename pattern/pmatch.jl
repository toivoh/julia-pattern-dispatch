

load("pattern/req.jl")
req("pattern/utils.jl")
req("pattern/core.jl")


# == code_pmatch: patterns --> matching code ==================================

type PMContext
    assigned_vars::Set{PVar}  # the PVar:s that have been assigned so far
    nomatch_ex    # expr to be returned if match fails
    code::Vector  # generated exprs

    PMContext(nomatch_ex) = new(Set{PVar}(), nomatch_ex, {})
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


function code_pmatch(c::PMContext, p::VarPattern,xname::Symbol)
    if has(c.assigned_vars, p)
        emit(c, code_iffalse_ret(c, 
            :( ($code_contains(p.dom,xname)) &&
               isequal_atoms(($p.var.name),($xname))
        )))
    else
        emit(c, :(
            ($p.name) = ($xname)
        ))   
        add(c.assigned_vars, p)
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

