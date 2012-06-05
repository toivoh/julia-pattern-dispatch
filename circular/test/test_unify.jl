
load("pattern/req.jl")
load("circular/nodepatterns.jl")
req("pretty/pretty.jl")
req("circular/test/utils.jl")

X, Y, Z = map(PVar, (:X, :Y, :Z))

@pshow unite(X, Y)
#@psymshow unite(X, Atom(1))
@pshow unite(X, Atom(1))

println()
@pshowln unite(X, TreeNode(Z, TuplePattern((Y, Atom(1)))))

println()
@pshow unite(Y, Atom(5))
@pshow unite( Atom(1), Atom(1))
@pshowln unite(TreeNode(X, TuplePattern((Y, Atom(1)))),
               TreeNode(Z, TuplePattern((Atom(5), Atom(1)))))
