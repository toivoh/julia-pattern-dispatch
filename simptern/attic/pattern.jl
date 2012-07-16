
require("simptern/pnode.jl")


abstract Pattern

type Atom{T} <: Pattern
    value::AtomNode{T}
    Atom(x::T) = new(AtomNode(x))
end
Atom{T}(x::T) = Atom{T}(x)

type TypeGuard <: Pattern
    T
end

type PVar <: Pattern
    name::Symbol
end

type TuplePattern <: Pattern
    elements::Vector{Pattern}
end
TuplePattern(args...) = TuplePattern(Pattern[args...])

type ProductPattern <: Pattern
    factors::Vector{Pattern}
end
ProductPattern(args...) = ProductPattern(Pattern[args...])

function make_net(p::Atom, source::PNode)
    g = egalnode(source, p.value)
    MatchNode(g)
end

function make_net(p::TypeGuard, source::PNode)
    g = isanode(source, p.T)
    MatchNode(g)
end

function make_net(p::PVar, source::PNode)
    MatchNode(truenode, {p.name => source})
end

function make_net(tp::TuplePattern, source::PNode)
    gtuple = isanode(source, Tuple)
    source_t = GateNode(source, gtuple)
    
    len = funcnode(length, source_t)
    glen = egalnode(len, length(tp.elements))
    source_tlen = GateNode(source_t, glen)
    
    factors = { MatchNode(andnode(gtuple, glen)) }
    for (pk,k) in enumerate(tp.elements)
        element = funcnode(ref, source_tlen, k)
        match_k = make_net(pk, element)
        push(factors, match_k)
    end
    meet(factors...)
end

function make_net(p::ProductPattern, source::PNode)
    meet({ make_net(factor, source) for factor in p.factors }...)
end
