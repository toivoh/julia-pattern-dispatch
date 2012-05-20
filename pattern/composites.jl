
load("pattern/req.jl")
req("pattern/utils.jl")
req("pattern/core.jl")
req("pattern/pmatch.jl")


type TuplePat <: Composite{Tuple}
    ps::Tuple
    TuplePat(args...) = new(map(aspattern, args))
end

show(io::IO, p::TuplePat) = print(io, "TuplePat$(p.ps)")
function show_unpatterned(io::IO, p::TuplePat)
#    show(io, p.ps)
    print("(")
    n = length(p.ps)
    for k=1:n
        show_unpatterned(io, p.ps[k])
        print(io, ",")
        if k<n; print(io, " "); end
    end
    print(")")
end


#isequal(x::TuplePat, y::TuplePat) = allp(isequal, x.ps,y.ps)
function isequal(xs::TuplePat, ys::TuplePat) 
     all({isequal(x,y) for (x,y) in zip(xs.ps,ys.ps)})
end
dom(::TuplePat) = universe  #domain(Tuple)

function aspattern(t::Tuple)
    p = TuplePat(t...)
    if any({is(x,nonematch) for x in p.ps}); return nonematch; end
    return p   
end

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

_ref(s::Subs, p::TuplePat) = aspattern(map(p->s[p], p.ps))

function unite(s::Subs, p::TuplePat,x::TuplePat)
    np, nx = length(p.ps), length(x.ps)
    if np!=nx; return unite(s, nonematch); end
    ys = cell(np)
    for k=1:np
        y = unite(s, p.ps[k], x.ps[k])
        if is(y, nonematch); return nonematch; end
        ys[k] = y
    end
    aspattern(tuple(ys...))
end
