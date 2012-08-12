
require("opat.jl")

type PatternFunction
    fname::Symbol
    methods::Vector

    PatternFunction(fname::Symbol) = new(fname, {})
end

function add(pf::PatternFunction, signature, body)
    push(pf.methods, (signature, body))
    eval(code_opat_fdef(pf.fname, pf.methods))
end


const patfun_table = Dict{Function,PatternFunction}()

macro pattern(fdef)
    code_pattern(fdef)
end
function code_pattern(fdef)
    fname, signature, body = split_fdef3(fdef)    
    pattern = recode(expr(:tuple, signature))
    
    quote
        mtable=nothing
        local fun
        try
            fun = ($esc(fname))
        catch e
            mtable = PatternFunction($quot(fname))
            const ($esc(fname)) = (args...)->dispatch((mtable), args)
            patfun_table[$esc(fname)] = mtable
        end
        if is(mtable, nothing)
            if !(isa(fun, Function) && has(patfun_table, fun))
                error("\nin @pattern method definition: ", ($string(fname)), 
                " is not a pattern function")
            end
            mtable = patfun_table[fun]
        end
        add(mtable, ($quot(pattern)), ($quot(body)))
    end
end