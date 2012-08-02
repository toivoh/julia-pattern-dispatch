
require("pattern/recshow.jl")
require("pattern/recode.jl")
require("pattern/utils.jl")

recshow(tuplepat(atompat(1),varpat(:x),typepat(Int))(Arg()))