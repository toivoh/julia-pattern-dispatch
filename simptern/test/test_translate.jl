
require("simptern/pnode.jl")
require("simptern/translate.jl")
require("simptern/code_match.jl")
require("pretty/pretty.jl")

arg = VarNode(:arg)
codepat(p::ArgPat) = code_match(makenet(arg, p))

@show codepat(atom(1))
@show codepat(@qpat 1)
println()
@show codepat(pvar(:x))
@show codepat(@qpat x)
println()
@show codepat(fixed_typeguard(Int))
@show codepat(@qpat ::Int)

println()
println()
@show codepat(tuplepat(atom(1), pvar(:x), fixed_typeguard(Int)))
@show codepat(@qpat (1, x, ::Int))

println()
println()
@show codepat(meetpats(pvar(:x), fixed_typeguard(Int)))
@show codepat(@qpat x~::Int)
@show codepat(@qpat x::Int)
