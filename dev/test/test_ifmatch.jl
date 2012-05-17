
load("utils/req.jl")
load("ifmatch.jl")
req("utils/utils.jl")

y=5
@ifmatch let x=1
    global y=x
    println("x = ", x)
end
assert y==1

println()
for k=1:5
    print("k = ", k)
    matched = @ifmatch let 2=k
        @assert k==2
        print(", == 2!")
    end
    @assert matched == (k==2)
    println()
end
