
load("utils/req.jl")
req("pmatch.jl")
req("utils/utils.jl")

@symshowln unify(1, nonematch)
@symshowln unify(nonematch, nonematch)

X = pvar(:X)
Y = pvar(:Y)

@symshowln unify(X, nonematch)
@symshowln unify(X, 1)
@symshowln unify(X, X)
@symshowln unify(X, Y)
