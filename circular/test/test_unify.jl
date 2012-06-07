
load("pattern/req.jl")
req("circular/nodepatterns.jl")
req("pretty/pretty.jl")
req("circular/test/utils.jl")

X, Y, Z, W = map(PVar, (:X, :Y, :Z, :W))

function test_unite(p, x)
    y, s = unite(p, x)
    print("unite(", psig(p), ", ", psig(x), ") = ", indent(psig(y)))
    println(indent(",\n", psig(s)))
end
function sym_test_unite(p, x)
    test_unite(p, x)
    test_unite(x, p)
end

test_unite_pairs = {
    (X, X), (X, Y), (X, Atom(1)), (Atom(1), Atom(1)), (Atom(1), Atom(5)),
    (X, TreeNode(Z, TuplePattern((Y, Atom(1))))),
    (TreeNode(X, TuplePattern((Y, Atom(1)))),
     TreeNode(Z, TuplePattern((Atom(5), Atom(1))))),
    (X, TreeNode(Y, TuplePattern((Atom(1), X))))
}


# @psymshowln unite(X, Y)
# @psymshowln unite(X, Atom(1))

# println()
# @pshowln unite(X, TreeNode(Z, TuplePattern((Y, Atom(1)))))

# println()
# @pshow unite( Atom(1), Atom(1))
# @pshowln unite(TreeNode(X, TuplePattern((Y, Atom(1)))),
#                TreeNode(Z, TuplePattern((Atom(5), Atom(1)))))

for (p,x) in test_unite_pairs
    println()
    sym_test_unite(p, x)
end