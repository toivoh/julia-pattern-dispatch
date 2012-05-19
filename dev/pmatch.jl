
load("utils/req.jl")
req("utils/utils.jl")
req("patterns.jl")


# == code_pmatch: patterns --> matching code ==================================

type PMContext
    assigned_vars::Set{PVar}  # the PVar:s that have been assigned so far
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
function code_pmatch_container(c::PMContext, ps,xsname::Symbol)
    emit(c, code_iffalse_ret(c, :(
        isa(($xsname),($quotevalue(get_containertype(ps)))) &&
        isequal(container_shape($xsname),($quotevalue(container_shape(ps))))
    )))
#     emit(c, code_iffalse_ret(c, :(isa(($xsname),($get_containertype(ps)))) ))
#     emit(c, code_iffalse_ret(c, :(
#       isequal(container_shape($xsname),($container_shape(ps)))
#     )))
    for (p, x_ex) in zip(ravel_container(ps), code_ravel_container(ps,xsname))
        xname = gensym("x")
        emit(c, :( ($xname)=($x_ex) ))
        code_pmatch(c, p,xname)
    end
end
function code_pmatch(c::PMContext, p,xname::Symbol)
    if is_container(p)
        code_pmatch_container(c, p,xname)
    else
        @assert isatom(p)
        emit(c, code_iffalse_ret(c, :(
            isequal_atoms(($quotevalue(p)),($xname))
        )))
    end
end


# == Subs: substitution from PVar:s to values/patterns ========================

# A substitution from pattern variables to patterns/values
type Subs
    dict::Dict{PVar,Any}  # substitions p::PVar => value: Domain/pattern
    nPgeX::Bool           # true if unite(s, P,X) has disproved that P >= X
    overdet::Bool         # true if no feasible substitution exists

    Subs() = new(Dict{PVar,Any}(), false, false)
end
nge!(s::Subs) = (s.nPgeX = true; s)

function show(io::IO,s::Subs) 
    ge = s.nPgeX ? "  " : ">="
    print(io, s.overdet ? "Nosubs($ge)" : "Subs($ge, $(s.dict))")
end

type Unfinished; end             
# Value of an unfinished computation. Used to detect cyclic dependencies.
const unfinished = Unfinished()

# rewrite all substitutions in s to depend only on free PVar:s
function unwind!(s::Subs)
    keys = [entry[1] for entry in s.dict]
    foreach(key->(s[key]), keys)
end

# s[p]:  apply the substitution s to the pattern p
ref(s::Subs, ::NonePattern) = nonematch
function ref(s::Subs, p::PVar)
    if s.overdet;  return nonematch;  end
    if has(s.dict, p)
        x = s.dict[p]
        if is(x, unfinished)
            # circular dependency ==> no finite pattern matches
            s.overdet = true
            return s.dict[p] = nonematch
        elseif isa(x, Domain)
            return restrict(p, x)
        elseif isatom(x)
            return x  # atoms can't be further substituted
        else
            # apply any relevant substitutions in s to x
            s.dict[p] = unfinished  # mark unfinished to avoid infinite loops
            x = s[x]                # look up recursively
            return s.dict[p] = x    # store new value and return
        end
    else
        return p  # free PVar ==> return p itself
    end
end
ref(s::Subs, p::DomPattern) = restrict(s[p.p], p.dom)
function ref(s::Subs, p)
    if is_container(p)
        # todo: early out if one element becomes nonematch?
        nm::Bool = false
        p = map_container(x->(x=s[x]; nm |= is(x,nonematch); x), p)
        nm ? nonematch : p
        # map_container(x->(x=s[x])
    else
        @assert isatom(p)
        p  # return atoms unchanged
    end
end

storesubs(s::Subs, p::PVar,x::DomPattern) = (s.dict[p] = is(x.p,p) ? x.dom : x)
storesubs(s::Subs, p::PVar,x) =             (if !is(x,p); s.dict[p] = x; end)
function unitesubs(s::Subs, p::PVar,x)
    if is(x,p);  return s[p];  end
    if has(s.dict, p)
        x0 = s[p]
        # todo: use a form of equality that corresponds to not introducing
        #       new constraints on p
        if is(x, x0);  return x0;  end

        # consider: any other cases when this is not a new constraint?
        # (especially when !s.nPgeX)

        # !s.nPgeX ==> this introduces constraints on rhs
        #          ==> s.nPgeX = true
        x = unite(nge!(s), x,x0)
    end
    storesubs(s, p, x)
end

# -- unify --------------------------------------------------------------------

# unify x and y into z
# return (z, substitution)
function unify(x,y)
    s = Subs()
    z = unite(s, x,y)
    if is(z, nonematch)
        # todo: move this into Subs/unite/check if it's already there
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


unite(s::Subs, ::NonePattern,x) = nonematch
unite(s::Subs, p::PVar,x) = unitesubs(s, p,x)

# consider: does this violate p>=x?
#           will it always converge? 
unite(s::Subs, p::DomPattern,x) = unite(s, p.p,restrict(p.dom,x))

function unite_containers(s::Subs, ps,xs)
#     (isequiv_containers(ps,xs) ? map_container((p,x)->unite(s, p,x), ps,xs) :
#                                  nonematch)
    if isequiv_containers(ps,xs)
        # todo: early out if one element becomes nonematch?
        nm::Bool = false
        zs = map_container((p,x)->(z=unite(s, p,x); nm |= is(z,nonematch); z),
                           ps,xs)
        nm ? nonematch : zs
    else
        nonematch
    end
end

function unite(s::Subs, p,x)
    @assert isatom(p)||is_container(p)
    
    # consider: should nge!(s) always be applied if x is a DomPattern?
    if isa(x, StrictPattern);     unite(nge!(s), x,p)  # ==> !(P >= X)
    elseif is_container(p); unite_containers(s, p,x)
    else;                   isequal_atoms(p,x) ? x : nonematch  # for atoms
    end
end
