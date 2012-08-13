
require("immutable.jl")

module Pat
import Base.*

export @pattern

load("utils.jl")
load("patbase.jl")
load("opat.jl")
load("pattern.jl")

end