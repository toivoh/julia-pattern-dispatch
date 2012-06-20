
load("pattern/req.jl")
#load("ternpat/ternpat.jl")
load("ternpat/code_match.jl")
req("pretty/pretty.jl")


arg  = VarNode(:arg)
gvec = typeguard(arg,Vector)

arglen = @ternpat (gvec; length(arg))
dlen   = egaldep(arglen, 2)

ref1 = @ternpat (dlen; ref(arg, 1))
ref2 = @ternpat (dlen; ref(arg, 2))

g1 = egaldep(ref1, 1)
g2 = egaldep(ref2, arg)

sinks = pnodeset(g1, g2)

show(code_match(sinks))
