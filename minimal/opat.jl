
require("patbase.jl")

# ---- @pattern ---------------------------------------------------------------

macro opat(block)
    code_opat(block)
end
function code_opat(block)
    @expect is_expr(block, :block)
    
    methods = {}
    fnames  = {}
    for fdef in block.args
        if is_linenumber(fdef) continue end
        sig, body = split_fdef(fdef)
        fname, signature = sig.args[1], sig.args[2:end]

        sigpat = recode(expr(:tuple, signature))
        push(methods, :(($sigpat), ($quot(body))))

        push(fnames, fname)
        @show signature
        @show sigpat
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
    for (p, body) in methods
        net = p(Arg())
        @show net

        code = code_match(net)
        @show(code)
        println()
        
        method_code = quote
            match, result = let
                ($code...)
                (true, ($body))
            end
            if match return result end
        end
        append!(body_code, method_code.args)
    end
    push(body_code, :( error($"no matching pattern for $fname") ))
#    @show expr(:block, body_code)

    fdef = :( ($fname)(($arg_symbol)...) = ($expr(:block, body_code)) )
    @show fdef
    fdef
end
