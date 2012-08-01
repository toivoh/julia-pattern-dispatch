
require("pattern/recode.jl")
require("pattern/utils.jl")

@show atompat(1)(Arg())
@show varpat(:x)(Arg())
@show typepat(Int)(Arg())

println()
@show tuplepat()(Arg())
println()
@show tuplepat(atompat(1))(Arg())
println()
@show tuplepat(varpat(:x))(Arg())
println()
@show tuplepat(typepat(Int))(Arg())

println()
@show tuplepat(atompat(1),varpat(:x),typepat(Int))(Arg())
