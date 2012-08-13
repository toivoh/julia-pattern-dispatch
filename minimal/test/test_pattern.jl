
load("patmod.jl")

module TestPattern
import Base.*
import Pat.*

load("utils.jl")

# so far: list patterns in order of priority:
@pattern f(1)       = 42
@pattern f(::Int)   = 5
@pattern f((x,y))   = x*y
@pattern f(x~{x,y}) = y
@pattern f({x,y})   = (x, y)
@pattern f(x)       = x
@pattern f(x,x)     = x
@pattern f(x,(y,z)) = (z,y,x)
@pattern f(x,y)     = x+y

@test f(1) === 42
@test f(2) === 5
@test f((6,5)) === 30
r={1,9}; r[1] = r
@test f(r) === 9 
@test f({1,2}) === (1,2)
@test f(2.5) === 2.5
@test f(4,4) === 4
@test f(1,(2,3)) === (3,2,1)
@test f(3,4) === 7

end
