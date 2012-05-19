
load("pattern/req.jl")
req("pattern/utils.jl")
req("pattern/core.jl")


type TuplePat <: Composite{Tuple}
    ps::Tuple
    TuplePat(args...) = new(map(aspattern, args))
end

show(io::IO, p::TuplePat) = print(io, "TuplePat$(p.ps)")

aspattern(p::Tuple) = TuplePat(p...)
