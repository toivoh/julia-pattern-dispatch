
load("utils/req.jl")
req("pmatch.jl")
req("utils/utils.jl")

@symshowln unify(1, nonematch)
@symshowln unify(nonematch, nonematch)

X, Y, Z = map(pvar, (:X, :Y, :Z))

@symshowln unify(X, nonematch)
@symshowln unify(X, 1)
@symshowln unify(X, X)
@symshowln unify(X, Y)

@assert pattern_gt(1, nonematch)
@assert pattern_eq(nonematch, nonematch)

@assert pattern_gt(X, nonematch)
@assert pattern_gt(X, 1)
@assert pattern_eq(X, X)
@assert pattern_eq(X, Y)

@assert unify(1, nonematch)[1] == nonematch
@assert unify(1, 1)[1] == 1
@assert unify(1, 2)[1] == nonematch
@assert unify(X, nonematch)[1] == nonematch
@assert unify(X, 3)[1] == 3
@assert unify(X, X)[1] == X
@assert unify(X, Y)[1] == Y
@assert unify(Y, X)[1] == X

println()
@symshowln unify(X, (1,2))
@symshowln unify((X,), (1,2))
@symshowln unify((X,Y), (1,2))
@symshowln unify((1,Y), (1,2))
@symshowln unify((1,Y), (X,2))
@symshowln unify((1,X,Y), (X,Y,Z))
@symshowln unify((1,Y,X), (X,Z,Y))
@symshowln unify((1,X,Y), (X,Y,2))
@symshowln unify((1,nonematch),(1,2))
@symshowln unify((X,Y),((Y,Y),(Z,Z)))

println()
@show z, s = unify(X,1)
@show s[({X,2},(X,3))]