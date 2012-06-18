
load("pattern/req.jl")
load("ternpat/code_match.jl")
req("pretty/pretty.jl")


arg = VarNode(:arg)
source = MeetNode(arg)

gvector = typeguard(source,Vector)

slen = @ternpat length(source) gvector
glength = egalguard(slen, 2)

ref1 = @ternpat ref(source, 1) glength
ref2 = @ternpat ref(source, 2) glength

pattern_matches = egalguard(ref1, 1)
meet!(source, ref2)


show(code_match(pattern_matches))
