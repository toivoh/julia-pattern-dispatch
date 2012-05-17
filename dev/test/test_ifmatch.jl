
load("utils/req.jl")
load("ifmatch.jl")
req("utils/utils.jl")

@ifmatch let x=1
    println("x = ", x)
end

println()
for k=1:5
    print("k = ", k)
    @ifmatch let 2=k
        print(", == 2!")
    end
    println()
end
