
#require("immutable.jl")
load("immutable.jl")

module TestImmutable
import Base.*
import Immutable.*
load("utils.jl")

@immutable type T
    x::Int
end

@test T(1) === T(1)
@test T(1) === T(1.0)
@test !(T(1) === T(2))

@immutable type S
    x::Int
    y
end

@test S(1,2) === S(1,2)
@test S(1,2) === S(1.0,2)
@test !(S(1,2) === S(1,2.0))
@test !(S(1,2) === S(2,2))
@test !(S(1,2) === S(1,1))

end
