
load("pattern/req.jl")
req("circular/recode.jl")
req("pretty/pretty.jl")


macro print_test(ex)
    quote
        println("@test (", ($sshow(ex)), ") == ", sshow($ex))
    end
end

function print_unite_test(px::PNode,py::PNode)
    pz, s = unite_ps(px,py)

    com=PNest(print, "unite(", psig(px), ", ", psig(py), 
                     ") = ", indent(psig(pz), ",\n", psig(s)))
    comment_str = string(com)
    comment_str = "# "*replace(comment_str, "\n", "\n# ")
    println(comment_str)

    print_sig("px, py, pz = @pattern ", px, " ", py, " ", pz, "\n")
    println("p, s = unite_ps(px,py)")
    println("@test egal(p,pz)")
    @print_test egal(px,pz)
    @print_test egal(py,pz)
    @print_test egal(px,py)
    @print_test s.disproved_p_ge_x
end

#create_unite_test((@pattern z x~(1,y))...)
unite_test_pairs = {
    (@pattern x x),
    (@pattern x y),
    (@pattern x 1),
    (@pattern 1 1),
    (@pattern 1 5),
    (@pattern x z~(y,1)),
    (@pattern x~(y,1) z~(5,1)),
    (@pattern x y~(1,x)),
}


println("load(\"pattern/req.jl\")")
println("req(\"circular/recode.jl\")")
println("req(\"circular/test/utils.jl\")")
println()

for (p,x) in unite_test_pairs
    println()
    println()
    print_unite_test(p,x)
    println("\n# reverse:")
    print_unite_test(x,p)    
end