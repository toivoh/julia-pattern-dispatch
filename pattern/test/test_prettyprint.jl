
require("pattern/prettyprint.jl")
require("pattern/recode.jl")

net=tuplepat(atompat(1),varpat(:x),typepat(Int))(Arg())

pprint(net)
