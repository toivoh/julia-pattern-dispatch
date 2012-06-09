

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


# == Subs: substitution from PatternVar:s to values/patterns ==================

type Unfinished; end             
# Value of an unfinished computation. Used to detect cyclic dependencies.
const unfinished = Unfinished()

# A substitution from pattern variables to patterns/values
typealias SubsDict Dict{PatternVar, Union(Pattern, Unfinished)}
type Subs
    dict::SubsDict  # substitions Var => value: Domain/pattern
    nPgeX::Bool     # true if unite(s, P,X) has disproved that P >= X
    overdet::Bool   # true if no feasible substitution exists

    Subs() = new(SubsDict(), false, false)
end
nge!(s::Subs) = (s.nPgeX = true; s)

function show(io::IO,s::Subs) 
    ge = s.nPgeX ? "  " : ">="
    print(io, s.overdet ? "Nosubs($ge)" : "Subs($ge, $(s.dict))")
end

# rewrite all substitutions in s to depend only on free PVar:s
function unwind!(s::Subs)
    keys = [entry[1] for entry in s.dict]
    foreach(key->(s[key]), keys)
end


ref(s::Subs, p::NonePattern) = nonematch
ref(s::Subs, p) = s.overdet ? nonematch : _ref(s, p)

_ref(s::Subs, p::Atom) = p
_ref(s::Subs, p::PVar) = restrict(s[p.var], p.dom)

function _ref(s::Subs, var::PatternVar) 
    has(s.dict, var) ? ref_var(s, var, s.dict[var]) : pvar(var)
end
function ref_var(s::Subs, var::PatternVar, x::Unfinished) 
    s.overdet = true
    return s.dict[var] = nonematch
end
ref_var(s::Subs, var::PatternVar, x::Atom) = x
function ref_var(s::Subs, var::PatternVar, x::PVar)
    is(x.var,var) ? x : reref_var(s, var, x)
end
ref_var(s::Subs, var::PatternVar, x::Pattern) = reref_var(s, var, x)

function reref_var(s::Subs, var::PatternVar, x::Pattern) 
    # apply any relevant substitutions in s to x
    s.dict[var] = unfinished  # mark unfinished to avoid infinite loops
    x = s[x]                  # look up recursively
    return s.dict[var] = x    # store new value and return    
end

function storesubs(s::Subs, var::PatternVar,::NonePattern) 
    nge!(s)
    return s.dict[var] = nonematch
end
function storesubs(s::Subs, var::PatternVar,x::PVar)
    if is(x.var, var) && is(x.dom, Universe); del(s.dict, var)
    else;                                     s.dict[var] = x
    end
end
storesubs(s::Subs, var::PatternVar,x::ValuePattern) = (s.dict[var] = x)

function unitesubs(s::Subs, var::PatternVar,x::Pattern)
    if has(s.dict, var)
        x0 = s[var]
#         if isa(x0, PVar) && is(x0.var, var)
#             x = restrict(x, x0.dom)
        if (isa(x0, PVar) && 
          (is(x0.var, var) || (isa(x,PVar) && is(x.var, x0.var))))
            x = restrict(x, x0.dom)
        else
            if isequal(x,x0); return x; end
            x = unite(nge!(s), x,x0)
        end
    end
    storesubs(s, var, x)
end


# -- unify --------------------------------------------------------------------

# unify x and y into z
# return (z, substitution)
function unify(x,y)
    s = Subs()
    z = unite(s, x,y)
    if is(z, nonematch)
        # todo: move this into Subs/unite/check if it's not already there
        s.overdet = true
        s.nPgeX = !is(y,nonematch)
    else        
        # make sure all available substitutions have been applied
        unwind!(s)
        z = s[z]
    end
    (z, s)
end

pattern_le(x,y) = (s=unify(y,x)[2]; !s.nPgeX)
pattern_ge(x,y) = (s=unify(x,y)[2]; !s.nPgeX)
pattern_eq(x,y) = pattern_le(x,y) && pattern_ge(x,y)
pattern_lt(x,y) = pattern_le(x,y) && !pattern_ge(x,y)
pattern_gt(x,y) = pattern_ge(x,y) && !pattern_le(x,y)


unite(s::Subs,  ::NonePattern) = (s.overdet=true; nonematch)
unite(s::Subs, p::PVar) = s.unitesubs(p.var, p)
unite(s::Subs, p::Composite) = error("unimplemented!")
unite(s::Subs, p::Atom) = p

unite(s::Subs, ::NoneDomain,::Pattern) = unite(s,nonematch)
function unite(s::Subs, p::PVar,x::RegularPattern)
    if dom(x) <= p.dom; unitesubs(s, p.var, x)
    else                unitesubs(nge!(s), p.var, restrict(x,p.dom))
    end
end
unite(s::Subs, p::Composite,x::ValuePattern) = error("unimplemented!")

unite(s::Subs, p::Atom,x::Atom) = isequal(p,x) ? x : unite(s, nonematch)
function unite(s::Subs, p::Pattern,x::Pattern)
    P, X = typeof(p).super, typeof(x).super
    if (P<:X) && !(X<:P); unite(nge!(s), x,p)
#    else; error("unimplmented: unite(Subs, ",typeof(p),","typeof(x),")")
    else; is(x,p) ? x : unite(s, nonematch)
    end
end
