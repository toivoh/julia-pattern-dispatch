

require("simptern/utils.jl")
require("simptern/immutable.jl")
require("pretty/pretty.jl")

ex = :(
    type T
        x::Float
        T(x) = new(x)
    end
)
ex2 = :(
    type T
        x
    end
)

println(code_immutable_type(ex))
println(code_immutable_type(ex2))

@immutable type T
    x::Float
    T(x) = new(x)
end
@immutable type T2
    x
end

println()
@show is(T(1),T(1))
@show is(T(1),T(1.0))
@show !is(T(1),T(2))

println()
@show is(T2(1),T2(1))
@show !is(T2(1),T2(1.0))
@show !is(T2(1),T2(2))

@assert is(T(1),T(1))
@assert is(T(1),T(1.0))
@assert !is(T(1),T(2))

@assert is(T2(1),T2(1))
@assert !is(T2(1),T2(1.0))
@assert !is(T2(1),T2(2))
