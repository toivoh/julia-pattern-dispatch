
require("simptern/pnode.jl")
require("simptern/translate.jl")
require("simptern/code_match.jl")
require("pretty/pretty.jl")

atom(x) = atom(AtomNode(x))
typeguard(T) = typeguard(AtomNode(T))

arg = VarNode(:arg)
codepat(p::ArgPat) = code_match(makenet(arg, p))

@show codepat(atom(1))
@show codepat(pvar(:x))
@show codepat(typeguard(Int))

println()
@show codepat(tuplepat(atom(1), pvar(:x), typeguard(Int)))
println()
@show codepat(meetpats(pvar(:x), typeguard(Int)))
