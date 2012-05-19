 
load("pattern/req.jl")
req("pattern/core.jl")
req("pattern/composites.jl")
load("pattern/pmatch.jl")

uni(x, y) = unify(aspattern(x), aspattern(y))
pat_gt(x, y) = pattern_gt(aspattern(x), aspattern(y))
pat_eq(x, y) = pattern_eq(aspattern(x), aspattern(y))

@symshowln uni(1, nonematch)
@symshowln uni(nonematch, nonematch)

X, Y, Z = map(pvar, (:X, :Y, :Z))

@symshowln uni(X, nonematch)
@symshowln uni(X, 1)
@symshowln uni(X, X)
@symshowln uni(X, Y)

@assert pat_gt(1, nonematch)
@assert pat_eq(nonematch, nonematch)

@assert pat_gt(X, nonematch)
@assert pat_gt(X, 1)
@assert pat_eq(X, X)
@assert pat_eq(X, Y)

@assert uni(1, nonematch)[1] == nonematch
@assert uni(1, 1)[1] == Atom(1)
@assert uni(1, 2)[1] == nonematch
@assert uni(X, nonematch)[1] == nonematch
@assert uni(X, 3)[1] == Atom(3)
@assert uni(X, X)[1] == X
@assert uni(X, Y)[1] == Y
@assert uni(Y, X)[1] == X

println()
@symshowln uni(X, (1,2))
@symshowln uni((X,), (1,2))
@symshowln uni((X,Y), (1,2))
@symshowln uni((1,Y), (1,2))
@symshowln uni((1,Y), (X,2))
@symshowln uni((1,X,Y), (X,Y,Z))
@symshowln uni((1,Y,X), (X,Z,Y))
@symshowln uni((1,X,Y), (X,Y,2))
@symshowln uni((1,nonematch),(1,2))
@symshowln uni((X,Y),((Y,Y),(Z,Z)))

@assert uni(X, (1,2))[1] == aspattern((1,2))
@assert uni((X,), (1,2))[1] == nonematch
@assert uni((X,Y), (1,2))[1] == aspattern((1,2))
@assert uni((1,Y), (1,2))[1] == aspattern((1,2))
@assert uni((1,Y), (X,2))[1] == aspattern((1,2))
@assert uni((1,X,Y), (X,Y,Z))[1] == aspattern((1,1,1))
@assert uni((1,Y,X), (X,Z,Y))[1] == aspattern((1,1,1))
@assert uni((1,X,Y), (X,Y,2))[1] == nonematch
@assert uni((1,nonematch),(1,2))[1] == nonematch
@assert uni((X,Y),((Y,Y),(Z,Z)))[1] == aspattern((((Z,Z),(Z,Z)),(Z,Z)))


println()
@show z, s = uni(X,1)
@show s[aspattern(((X,2),(X,3)))]
