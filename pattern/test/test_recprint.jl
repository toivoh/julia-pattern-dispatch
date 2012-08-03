
require("pattern/recprint.jl")
require("pattern/recode.jl")

net=tuplepat(atompat(1),varpat(:x),typepat(Int))(Arg())

recshow(net)

println()
recshow2(net)
