
require("simptern/code_match.jl")
require("simptern/pattern.jl")
require("pretty/pretty.jl")

source = VarNode(:arg)

codepat(p) = (global source; code_match(make_net(p, source)))


@show codepat(Atom(1))
@show codepat(TypeGuard(Int))
@show codepat(PVar(:x))
