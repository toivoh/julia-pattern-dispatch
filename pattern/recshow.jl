
require("pattern/customio.jl")

type RecIO <: CustomIO
    printed::Dict{Any, blubb}
end

print(io::RecIO, x)
