
load("pattern/req.jl")
req("circular/nodepatterns.jl")
req("circular/recode.jl")
req("pretty/pretty.jl")
req("circular/test/utils.jl")

X, Y, Z, W = map(PVar, (:X, :Y, :Z, :W))

function test_unite(p, x)
    y, s = unite_ps(p, x)
    print("unite(", psig(p), ", ", psig(x), ") = ", indent(psig(y)))
    println(indent(",\n", psig(s)))
end
function sym_test_unite(p, x)
    test_unite(p, x)
    test_unite(x, p)
end

test_unite_pairs = {
    (X, X), (@pattern X X),
    (X, Y), (@pattern X Y),
    (X, Atom(1)), (@pattern X 1),
    (Atom(1), Atom(1)), (@pattern 1 1),
    (Atom(1), Atom(5)), (@pattern 1 5),
    (X, TreeNode(Z, TuplePattern((Y, Atom(1))))), (@pattern X Z~(Y,1)),
    (TreeNode(X, TuplePattern((Y, Atom(1)))),
     TreeNode(Z, TuplePattern((Atom(5), Atom(1))))),
    (@pattern X~(Y,1) Z~(5,1)),
    (X, TreeNode(Y, TuplePattern((Atom(1), X)))), 
    (@pattern X Y~(1,X)),
}


# @psymshowln unite_ps(X, Y)
# @psymshowln unite_ps(X, Atom(1))

# println()
# @pshowln unite_ps(X, TreeNode(Z, TuplePattern((Y, Atom(1)))))

# println()
# @pshow unite_ps( Atom(1), Atom(1))
# @pshowln unite_ps(TreeNode(X, TuplePattern((Y, Atom(1)))),
#                TreeNode(Z, TuplePattern((Atom(5), Atom(1)))))

for (p,x) in test_unite_pairs
    println()
    sym_test_unite(p, x)
end