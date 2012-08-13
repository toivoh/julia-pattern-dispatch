
require("patbase.jl")

# ---- @pattern ---------------------------------------------------------------

macro opat(block)
    code_opat(block)
end
function code_opat(block)
    @expect is_expr(block, :block)
    
    methods, fnames = {}, {}
    for fdef in block.args
        if is_linenumber(fdef) continue end
        fname, method = recode_fdef(fdef)
        push(fnames, fname)
        push(methods, method)
    end
    fname = common_value(fnames)
    @show fname

    quote
        fdef = code_opat_fdef(($quot(fname)), $methods...)
        eval(fdef)
    end
end

function code_opat_fdef(fname::Symbol, methods...)
    body_code = {}
    for m in methods
        @show m.sig

        matchcode = code_match(m.sig)
        @show(matchcode)
        println()
        
        method_code = quote
            match, result = let
                ($matchcode...)
                (true, ($quot(m.body))($m.args...))
            end
            if match return result end
        end
        append!(body_code, method_code.args)
    end
    push(body_code, :( error($"no matching pattern for $fname") ))

    fdef = :( ($fname)(($arg_symbol)...) = ($expr(:block, body_code)) )
    @show fdef
    fdef
end
