
load("pattern/req.jl")
req("pattern/core.jl")
req("pattern/composites.jl")
load("pattern/pmatch.jl")


let
    uni(x, y) = unify(aspattern(x), aspattern(y))

    X, Y, Z = map(pvar, (:X, :Y, :Z))
    
    @symshowln uni(X, (1,2))
    @symshowln uni((X,2), (1,2))
    @symshowln uni((X,1), (1,2))
    @symshowln uni((1,X), (1,2))
    @symshowln uni((1,X), (Y,2))
    @symshowln uni((1,X), (1,2,3))
    @symshowln uni((1,X,Y), (1,2,3))
    @symshowln uni((1,X), (1,(2,3)))
    
    println()
    @symshowln uni((1,X), (X,Y))
    @symshowln uni((1,X,Y), (X,Y,Z))
    @symshowln uni((1,X,Y), (X,Y,1))
    @symshowln uni((1,X,Y), (X,Y,2))
    @symshowln uni((1,Y,X), (X,Z,Y))
    @symshowln uni(X, (1,X))

#     println()
#     @pvar Xi::Int, Xa::Array, Xv::Vector, Xm::Matrix
#     @symshowln uni(Xi, (1,2))
#     @symshowln uni(Xa, (1,2))
#     @symshowln uni(Xv, (1,2))
#     @symshowln uni(Xm, (1,2))

#     println()
#     @pvar Xai::Array(Int)
#     @symshowln uni(Xai, (1,2))
#     @symshowln uni(Xai, [1,2])
#     @symshowln uni(Xa, [1,2,X])

#     # consider: Should this work? And force X to be an Int.
#     @symshowln uni(Xai, [1,2,X])
end
