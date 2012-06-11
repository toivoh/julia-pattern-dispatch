
load("pattern/req.jl")
req("pattern/nodepatterns.jl")
req("pattern/recode.jl")
req("pattern/test/utils.jl")
req("pretty/pretty.jl")

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
    (X, X), (@qpat X X),
    (X, Y), (@qpat X Y),
    (X, Atom(1)), (@qpat X 1),
    (Atom(1), Atom(1)), (@qpat 1 1),
    (Atom(1), Atom(5)), (@qpat 1 5),
    (X, TreeNode(Z, TuplePattern((Y, Atom(1))))), (@qpat X Z~(Y,1)),
    (TreeNode(X, TuplePattern((Y, Atom(1)))),
     TreeNode(Z, TuplePattern((Atom(5), Atom(1))))),
    (@qpat X~(Y,1) Z~(5,1)),
    (X, TreeNode(Y, TuplePattern((Atom(1), X)))), 
    (@qpat X Y~(1,X)),
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
