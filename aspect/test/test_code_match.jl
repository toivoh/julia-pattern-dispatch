
load("pattern/req.jl")
load("aspect/pattern.jl")

req("pattern/utils.jl")
req("prettyshow/prettyshow.jl")
show(io::IO, ex::Expr) = pshow(io, ex)

function code(p::Pattern)
    c=CMContext()
    code_match(c, p,:value)
    expr(:block, c.code)
end

plabel(label::Label) = ObjectPattern(label,())
patom(value) = plabel(Atom(value))
pvar(name::Symbol) = plabel(Var(name))

ppat(p::AspectPattern) = ObjectPattern(Var(gensym()), [p])
ppat(key::AspectKey, p::Pattern) = ppat(AspectPattern(key, p))
#ppat(key::AspectKey, args...)=ppat(key, pattype(key.aspect)(args...))
function pindpat(key::AspectKey, subkey, p::ObjectPattern)
    ppat(key, pattype(key.aspect)({subkey=>p}))
end

pfunc (f::Function,  p::ObjectPattern) = pindpat(func_asp,  f,     p)
pfield(name::Symbol, p::ObjectPattern) = pindpat(field_asp, name,  p)
pref  (index::Tuple, p::ObjectPattern) = pindpat(ref_asp,   index, p)
papply(args::Tuple,  p::ObjectPattern) = pindpat(apply_asp, args,  p)


@show code(TypePattern(Int))
@show code(patom(42))
@show code(pvar(:x))

println()
@show code(pfunc(length, patom(3)))
@show code(pfield(:x, patom(11)))
@show code(pref((2,), patom(12)))
@show code(papply((2,11), patom(-1)))

