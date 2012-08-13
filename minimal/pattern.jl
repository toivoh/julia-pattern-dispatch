
type PatternFunction
    fname::Symbol
    methods::Vector{PatternMethod}

    PatternFunction(fname::Symbol) = new(fname, PatternMethod[])
end

function add(pf::PatternFunction, m::PatternMethod)
    push(pf.methods, m)
    eval( code_pattern_function(pf.fname, pf.methods) )
end


const patfun_table = Dict{Function,PatternFunction}()

get_pf(fname::Symbol, ::Nothing) = PatternFunction(fname)
function get_pf(fname::Symbol, f::Function)
    if !has(patfun_table, f) pf_error(fname); end
    patfun_table[f]
end
get_pf(fname::Symbol, f) = pf_error(fname)
function pf_error(fname::Symbol)
    error("\nin @pattern method definition: $fname is not a pattern function")
end

macro pattern(fdef)
    code_pattern(fdef)
end
function code_pattern(fdef)
    fname, method_ex = recode_fdef(fdef)
    
    quote
        f = nothing
        try
            f = ($esc(fname))
        end
        pf = get_pf($quot(fname), f)
        add(pf, $method_ex)
        
        if f === nothing; patfun_table[$esc(fname)] = pf; end
    end
end
