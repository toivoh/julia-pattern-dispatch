
load("pattern/req.jl")
req("pattern/core.jl")
req("pattern/composites.jl")
load("pattern/ifmatch.jl")

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

println()
@ifmatch let (x,y,3)=(1,2,3)
    @show x,y
end
@ifmatch let {x,y,4}={2,3,4}
    @show x,y
end
@ifmatch let {x,x,4}={3,3,4}
    @show x
end
@ifmatch let {{x},{x},7}={{4},{4},7}
    @show x
end
@ifmatch let {x,x,7}={{4,5},{4,5},7}
    @show x
end


# no-matches:
@ifmatch let {x,y,3}=(6,5,3)
    @show x,y
end
@ifmatch let (x,y,3)=(6,5,4)
    @show x,y
end
@ifmatch let (x,y,3)=(6,5)
    @show x,y
end
@ifmatch let {{x},4}={{4,5},4}
    @show x
end


println()
@ifmatch let x::Int=3
    @show x
end
@ifmatch let x::Int=3.0
    @show x
end
@ifmatch let x::Int="nnkj"
    @show x
end
