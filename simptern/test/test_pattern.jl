
require("simptern/code_match.jl")
require("simptern/pattern.jl")
require("simptern/recode.jl")
require("pretty/pretty.jl")

source = VarNode(:arg)

codepat(p) = (global source; code_match(make_net(p, source)))


@show codepat(Atom(1))
@show codepat(TypeGuard(Int))
@show codepat(PVar(:x))
@show codepat(TuplePattern(Atom(1), PVar(:x)))

println()
@show codepat(@qpat 1)
@show codepat(@qpat ::Int)
@show codepat(@qpat x)
@show codepat(@qpat (1, ::Int, x))
@show codepat(@qpat x~(1,y::Int))
