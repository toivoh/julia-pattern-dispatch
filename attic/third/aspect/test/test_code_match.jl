
load("pattern/req.jl")
load("aspect/pattern.jl")

req("pattern/utils.jl")
#req("prettyshow/prettyshow.jl")
#show(io::IO, ex::Expr) = pshow(io, ex)

function code(p::Pattern)
    c=CMContext()
    code_match(c, p,:value)
    expr(:block, c.code)
end

function pattern(p::ObjectPattern, factors::AspectPattern...)
    ObjectPattern(p.labels, p.factors..., factors...)
end
function pattern(label::LabelPattern, factors::AspectPattern...)
    ObjectPattern([label], factors...)
end
pattern(factors::AspectPattern...) = pattern(Var(gensym()), factors...)


patom(value) = Atom(value)
pvar(name::Symbol) = PVar(name)

pkey(key::AspectKey, p::Pattern) = pattern(KeyPattern(key, p))
function pkey(key::AspectKey, subkey, p::ObjectPattern)
    pkey(key, pattype(key.aspect)({subkey=>p}))
end

pfunc (f::Function,  p::ObjectPattern) = pkey(func_asp,  f,     p)
pfield(name::Symbol, p::ObjectPattern) = pkey(field_asp, name,  p)
pref  (index::Tuple, p::ObjectPattern) = pkey(ref_asp,   index, p)
papply(args::Tuple,  p::ObjectPattern) = pkey(apply_asp, args,  p)



@show TypePattern(Int)
@show patom(42)
@show pvar(:x)

println()
@show pfunc(length, patom(3))
@show pfield(:x, patom(11))
@show pref((2,), patom(12))
@show papply((2,11), patom(-1))

println()

@show code(TypePattern(Int))
@show code(patom(42))
@show code(pvar(:x))

println()
@show code(pfunc(length, patom(3)))
@show code(pfield(:x, patom(11)))
@show code(pref((2,), patom(12)))
@show code(papply((2,11), patom(-1)))

println()
@show TypePattern(Int)
@show patom(42)
@show pvar(:x)

println()
@show pfunc(length, patom(3))
@show pfield(:x, patom(11))
@show pref((2,), patom(12))
@show papply((2,11), patom(-1))

