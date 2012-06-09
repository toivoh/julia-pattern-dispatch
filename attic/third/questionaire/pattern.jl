
abstract Aspect
abstract   PropertyAspect <: Aspect

type AspectNode{T<:Aspect}
    name::String
    aspect::T
    deps::Vector{AspectNode}

    function AspectNode(name::String, aspect::T, deps)
        new(name, aspect, AspectNode[deps...])
    end
end
typealias PropertyNode AspectNode{Property}

abstract Pattern

abstract SetPattern
abstract   AspectPattern <: SetPattern
abstract     IntegralPattern <: AspectPattern
abstract       ItemsPattern <: IntegralPattern


type Var
    name::Symbol
end


type Atom{T} <: Pattern
    value::T
end

type VarPattern <: Pattern
    var::Var
    p::SetPattern
end


type ProductPattern <: SetPattern
    factors::Vecotr{AspectPattern}
end

type PropertyPattern
    prop::PropertyNode
    p::Pattern
end


type TypePattern <: IntegralPattern
    T
end



type IntegralAspect{T<:IntegralPattern} <: Aspect; end
typealias IntegralNode AspectNode{IntegralAspect}
integralnode(name, T, deps) = IntegralNode(name, IntegralAspect{T}, deps)


type_asp   = integralnode("type", TypePattern, [])

length_asp = PropertyNode("length", Getter(length), [type_asp])
size_asp   = PropertyNode("size",   Getter(size),   [type_asp])

items_asp  = integralnode("items", ItemsPattern, [length_asp, size_asp])

