

require("simptern/utils.jl")
require("simptern/immutable.jl")
require("pretty/pretty.jl")

ex = :(
    type T
        x::Float
        T(x) = new(x)
    end
)

println(code_immutable_type(ex))

@immutable type T
    x::Float
    T(x) = new(x)
end

println()
@show is(T(1),T(1))
@show is(T(1),T(1.0))
@show is(T(1),T(2))
