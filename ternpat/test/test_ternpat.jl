
load("pattern/req.jl")
load("ternpat/ternpat.jl")
req("pretty/pretty.jl")


source = MeetNode()

gvector = typeguard(source,Vector)

slen = @ternpat length(source) gvector
glength = egalguard(slen, 2)

ref1 = @ternpat ref(source, 1) glength
ref2 = @ternpat ref(source, 2) glength

pattern_matches = egalguard(ref1, 1)
meet!(source, ref2)

