
load("pattern/req.jl")
load("pattern/core.jl")
load("pattern/composites.jl")
load("pattern/recode.jl")
req("prettyshow/prettyshow.jl")

function show_recode(ex)
    println()
    @pshow ex
    try
        @pshow p=eval(recode_pattern_ex(ex, true))
        @pshow aspattern(p)
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
show_recode(:(x::Int))
#println()
#@pshowln recode_pattern_ex(:(x::Int))


@assert eval(recode_pattern_ex(:1, true)) == 1
#@assert (eval(recode_pattern_ex(:x))::PVar).name == :x
@assert eval(recode_pattern_ex(:(1,2), true)) == (1,2)
# @assert (eval(recode_pattern_ex(:(x,2)))::(PVar,Int))[2] == 2
# @assert is(eval(recode_pattern_ex(:(x,x)))::(PVar,PVar)...)
# @assert !is(eval(recode_pattern_ex(:(x,y)))::(PVar,PVar)...)


