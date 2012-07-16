
require("simptern/pnode.jl")
require("simptern/translate.jl")
require("simptern/code_match.jl")


global const pat_arg = gensym("arg")


# -- Pattern interface: -------------------------------------------------------

type Pattern
    arg::VarNode
    match::MatchNode
end

# i/f: recode_patex(ex) from translate.jl

pattern(arg::VarNode, p::ArgPat) = Pattern(arg, makenet(arg, p))
pattern(p::ArgPat) = pattern(VarNode(pat_arg), p)

get_argname(p::Pattern) = p.arg.name
get_varnames(p::Pattern) = get_symbol_names(p.match)
code_match(p::Pattern, args...) = code_match(p.match, args...)
