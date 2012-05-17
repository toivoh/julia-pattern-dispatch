
load("utils/req.jl")
req("utils/utils.jl")
req("patterns.jl")


# == code_pmatch: patterns --> matching code ==================================

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
function ref(s::Subs, x)
    @assert isatom(x)
    x  # return atoms unchanged
end

function unitesubs(s::Subs, V::PVar,p)
    if has(s.dict, V)
        p0 = s[V]  # look up the refined value of V
        # consider: any other cases when this is not a new constraint?
        # (especially when !s.nPgeX)
        if is(p,V) || isequal(p,p0);  return p0;  end
        # !s.nPgeX ==> this introduces constraints on rhs
        #          ==> s.nPgeX = true
        pnew = unite(nge!(s), p0,p)    # unite the new value with the old
        return s.dict[V] = pnew        # store the result and return
    else
        if is(p,V)  return p;  end
        s.dict[V] = p  # no old binding: store and return the new one
    end
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


unite(s::Subs, ::NonePattern,x) = nonematch
unite(s::Subs, p::PVar,x) = unitesubs(s, p,x)

# consider: does this violate p>=x?
#           will it always converge? 
unite(s::Subs, p::DomPattern,x) = unite(s, p.p,restrict(p.dom,x))

function unite(s::Subs, p,x)
    @assert isatom(p)
    if isa(x, Pattern); unite(nge!(s), x, p)               # ==> !(P >= X)
    else;               isequalatoms(p,x) ? x : nonematch  # for atoms
    end
end