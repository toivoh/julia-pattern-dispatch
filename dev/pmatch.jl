
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
get_varnames(c::PMContext) = {p.name for p in c.assigned_vars}

function code_iffalse_ret(c::PMContext, pred)
    :(if !($pred)
        return ($c.nomatch_ex)
    end)
end

## code_pmatch: create pattern matching code from pattern ##
function code_pmatch(p,xname::Symbol)
    c = PMContext()
    code_pmatch(c, p,xname)
    expr(:block, c.code)
end


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
    emit(c, code_iffalse_ret(c, :(isequal_atoms(($quotevalue(p)),($xname))) ))
end

