
require("pattern/recprint.jl")


type T
    x
    y
end

t = T(1,2)
s = T(t,t)

rec = record_show(s)


