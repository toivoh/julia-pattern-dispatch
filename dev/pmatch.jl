
load("utils/req.jl")
req("utils/utils.jl")
req("patterns.jl")


type PMContext
    assigned_vars::Set{PVar}
    nomatch_ex    # expr to be returned if match fails
    code::Vector  # generated exprs

    PMContext(nomatch_ex) = new(Set{PVar}(), nomatch_ex, {})
    PMContext() = PMContext(:false)
end
emit(c::PMContext, ex) = (push(c.code,ex); nothing)

function code_iffalse_ret(c::PMContext, pred)
    :(if !($pred)
        return ($c.nomatch_ex)
    end)
end

## code_pmatch: create pattern matching code from pattern ##
function code_pmatch(c::PMContext, p::NonePattern,xname::Symbol)
    error("code_pmatch: pattern never matches")
end
function code_pmatch(c::PMContext, p::PVar,xname::Symbol)
    if has(c.assigned_vars, p)
        emit(c, code_iffalse_ret(c, :(isequal_atoms(($p.name),($xname))) ))
    else
        emit(c, :(
            ($p.name) = ($xname)
        ))        
        add(c.assigned_vars, p)
    end
end
function code_pmatch(c::PMContext, p::DomPattern,xname::Symbol)
    emit(c, code_iffalse_ret(c, code_contains(p.dom,xname)))
    code_pmatch(c, p.p,xname)
end
function code_pmatch(c::PMContext, p,xname::Symbol)
    @expect isatom(p)
    emit(c, code_iffalse_ret(c, :(isequal_atoms(($quoted_expr(p)),($xname))) ))
end

