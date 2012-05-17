
load("utils/req.jl")
load("recode.jl")
req("utils/utils.jl")
req("../prettyshow/prettyshow.jl")

function show_recode(ex)
    println()
    @pshow ex
    try
        @pshow eval(recode_pattern_ex(ex))
    catch err
        @pshowln recode_pattern_ex(ex)
        throw(err)
    end
    @pshowln recode_pattern_ex(ex)
end

show_recode(:1)
show_recode(:x)
show_recode(:(1,2))
show_recode(:(x,2))
show_recode(:(x,x))
show_recode(:(x,y))
#show_recode(:(x::Int))
println()
@pshowln recode_pattern_ex(:(x::Int))
