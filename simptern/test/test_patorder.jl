
require("simptern/pnode.jl")
require("simptern/unify.jl")
require("simptern/recode.jl")

function compare(p::Pattern, q::Pattern)
    source = VarNode(:arg)
    compare(make_net(p, source).guard, make_net(q, source).guard)
end

function compare(n::PNode, m::PNode)
    if ternpat_eq(n, m);     :(==)
    elseif ternpat_le(n, m); :(<=)
    elseif ternpat_ge(n, m); :(>=)
    else;                    :unordered
    end
end

@show compare((@qpat x y)...)
@show compare((@qpat x y::Int)...)
@show compare((@qpat x::Int y)...)
@show compare((@qpat x::Int y::Float)...)
@show compare((@qpat x~(1,2) y~(1,z))...)
