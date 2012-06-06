
load("pattern/req.jl")
req("circular/nodepatterns.jl")
req("pretty/pretty.jl")
req("circular/test/utils.jl")

X, Y, Z = map(PVar, (:X, :Y, :Z))

@psymshowln unite(X, Y)
@psymshowln unite(X, Atom(1))

println()
@pshowln unite(X, TreeNode(Z, TuplePattern((Y, Atom(1)))))

println()
@pshow unite( Atom(1), Atom(1))
@pshowln unite(TreeNode(X, TuplePattern((Y, Atom(1)))),
               TreeNode(Z, TuplePattern((Atom(5), Atom(1)))))
