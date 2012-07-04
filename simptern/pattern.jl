
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

type TupplePattern <: Pattern
    elements::Vector{Pattern}
end


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

function make_net(tp::TupplePattern, source::PNode)
    gtuple = isanode(source, Tuple)
    source_t = GateNode(source, gtuple)
    
    len = funcnode(length, source_t)
    glen = egalnode(len, length(tp.elements))
    source_tlen = GateNode(source_t, glen)
    
    match = MatchNode(andnode(gtuple, glen))
    for (p,k) in enumerate(tp.elements)
        element = funcnode(ref, source_tlen, k)
        match_k = make_net(p, element)
        match = match & match_k
    end
    match
end
