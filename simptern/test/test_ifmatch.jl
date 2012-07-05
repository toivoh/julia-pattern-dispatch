
require("simptern/ifmatch.jl")

@ifmatch let x=1
    println(x)
end
@ifmatch let x=(2,3)
    println(x)
end
@ifmatch let 1=1
    println("ok(4)")
end
t=5
@ifmatch let x=t
    println(5)
end
t=6
@ifmatch let 6=t
    println("ok(6)")
end
@ifmatch let (x,y)=(7,8)
    println((x,y))
end
@ifmatch let (z~(x,y))=(9,10)
    println(z)
end
@ifmatch let (z~(11,y))=(11,12)
    println(z)
end
println("disabled tests: 13, 14, 15")
# @ifmatch let (x,x)=(13,13)
#     println(x)
# end
# t=("14","15")
# @ifmatch let (x,x)=(t,t)
#     println(x)
# end
@ifmatch let (w~(x,(y,z)))=(16,((17,18),19))
    println(w)
end



t=11
@ifmatch let 6=t
    println("shouldn't match!")
end
@ifmatch let (11,y)=11
    println("shouldn't match!")
end
@ifmatch let (x,y)=11
    println("shouldn't match!")
end
@ifmatch let (x,y)=(11,)
    println("shouldn't match!")
end
# @ifmatch let (x,x)=(11,8)
#     println("shouldn't match!")
# end
@ifmatch let (w~(x,(y,z)))=(16,(17,18,19))
    println("shouldn't match!")
end
