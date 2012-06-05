
load("pattern/req.jl")
load("circular/nodepatterns.jl")
#req("pretty/pretty.jl")
req("circular/test/utils.jl")

X, Y, Z = map(PVar, (:X, :Y, :Z))

@show unite(X, Y)
#@symshow unite(X, Atom(1))
@show unite(X, Atom(1))

println()
@showln unite(X, TreeNode(Z, TuplePattern((Y, Atom(1)))))

println()
@show unite(Y, Atom(5))
@show unite( Atom(1), Atom(1))
@showln unite(TreeNode(X, TuplePattern((Y, Atom(1)))),
              TreeNode(Z, TuplePattern((Atom(5), Atom(1)))))
