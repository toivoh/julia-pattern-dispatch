
load("pattern/req.jl")
req("pattern/utils.jl")
req("pattern/core.jl")
req("pattern/pmatch.jl")


type TuplePat <: Composite{Tuple}
    ps::Tuple
    TuplePat(args...) = new(map(aspattern, args))
end

show(io::IO, p::TuplePat) = print(io, "TuplePat$(p.ps)")

isequal(x::TuplePat, y::TuplePat) = allp(isequal, x.ps,y.ps)


aspattern(p::Tuple) = TuplePat(p...)

function code_pmatch(c::PMContext, p::TuplePat,xname::Symbol)
    np = length(p.ps)
    emit(c, code_iffalse_ret(c,  :(
        (isa(($xname),Tuple) && length($xname) == ($np))
    )))
    for k=1:np
        xname_k = gensym()
        emit(c, :(($xname_k) = ($xname)[$k]))
        code_pmatch(c, p.ps[k], xname_k)
    end
end

function unite(s::Subs, ps::TuplePat,xs::TuplePat)
    np, nx = length(ps), length(xs)
    if np!=nx; return unitesubs(s, nonematch); end
    ys = Array(T, np)
    for k=1:np
        y = unite(s, ps[k], xs[k])
        if is(y, nonematch); return nonematch; end
        ys[k] = y
    end
    tuple(ys...)
end
