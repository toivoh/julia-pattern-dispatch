
require("patbase.jl")

# ---- @pattern ---------------------------------------------------------------

macro opat(block)
    code_opat(block)
end
function code_opat(block)
    @expect is_expr(block, :block)
    
    methods, fnames = {}, {}
    for fdef in filter(fdef->!is_linenumber(fdef), block.args)
        fname, method = recode_fdef(fdef)
        push(fnames, fname)
        push(methods, method)
    end
    fname = common_value(fnames)
    @show fname

    :(eval( code_pattern_function(($quot(fname)), $methods...) ))
end
