
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
        fname, signature, body = split_fdef3(fdef)

        vars, pattern = recode(expr(:tuple, signature))
        bodyfun = expr(:(->), expr(:tuple, vars...), body)
        @show bodyfun
        push(methods, :(($pattern), ($quot(vars)), ($bodyfun)))

        push(fnames, fname)
        @show signature
        @show vars
        @show pattern
        @show methods[end].args[3]
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
    for (p, argnames, fun) in methods
        net = p(Arg())
        @show net

        code = code_match(net)
        @show(code)
        println()
        
        method_code = quote
            match, result = let
                ($code...)
                (true, ($quot(fun))($argnames...))
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