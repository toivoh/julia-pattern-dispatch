# Ideas for guard condition syntax:

[x where x > 0]

f([ ::Real where  == 0]) = 42

f([where==0]::Real)      = 42
f([x::Real where x > 0]) =  x
f([x::Real where x < 0]) = -x


f( ::Real ~equalto(0))   = 42 
f(x::Real ~where(x > 0)) =  x
f(x::Real ~where(x < 0)) = -x

f(equalto(0)::Real) = 42 
f(x::Real ~(x > 0)) =  x
f(x::Real ~(x < 0)) = -x

f( ::Real ~equalto(0))   = 42 
f(x ~where(x::Real > 0)) =  x
f(x ~where(x::Real < 0)) = -x


(x::Real ~where(x > 0))
(x::(Real&where(x > 0)))
(x::(Real ~ x>0))


(x ~where(x > 0))
(x ~where(x > 0)&odd)

(x ~where(x > 0) & where(x < 5))
(x ~where(0 < x < 5))
(x ~range(0,5))
(x ~positive)
(x ~domain(Int))
(x ~equalto(2))
(x ~where(x==2))
f(::equalto(2)) = 5
f( ~equalto(2)) = 5
x::where(x > 0)
x::st(x > 0)


(x ~isa(Int))

f(0) = 42
f(x ~where(x > 0)) =  x
f(x ~where(x < 0)) = -x

f(0) = 42
f(x | where(x > 0)) =  x
f(x | where(x < 0)) = -x

f(0) = 42
f(x: where(x > 0)) =  x
f(x: where(x < 0)) = -x

f(0) = 42
f(x: [x > 0]) =  x
f(x: [x < 0]) = -x

f(0) = 42
f(x: {x > 0}) =  x
f(x: {x < 0}) = -x

f(0) = 42
f(x::[x > 0]) =  x
f(x::[x < 0]) = -x

f(0) = 42
f(x::{x > 0}) =  x
f(x::{x < 0}) = -x

f(x^where(x > 0)) =  x
f(x^where(x < 0)) = -x

f(0) = 42
f(x \where(x > 0)) =  x
f(x \where(x < 0)) = -x

f(0) = 42
f(x //where(x > 0)) =  x
f(x //where(x < 0)) = -x

f(0) = 42
f(x where x > 0) =  x
f(x where x < 0) = -x

f(0) = 42
f(x::where(x > 0)) =  x
f(x::where(x < 0)) = -x

f(0) = 42
f(x::st(x > 0)) =  x
f(x::st(x < 0)) = -x

f(0) = 42
f(x ~ {x > 0}) =  x
f(x ~ {x < 0}) = -x

f(0) = 42
f(x ~ (x > 0)) =  x
f(x ~ (x < 0)) = -x

f(0) = 42
f(x ~ [x > 0]) =  x
f(x ~ [x < 0]) = -x

f(0) = 42
f(x | x > 0) =  x
f(x | x < 0) = -x

f(0) = 42
f(x | (x > 0)) =  x
f(x | (x < 0)) = -x

f(0) = 42
f(x: x > 0) =  x
f(x: x < 0) = -x

f(0) = 42
f(x: (x > 0)) =  x
f(x: (x < 0)) = -x

f(0) = 42
f(x::(x > 0)) =  x
f(x::(x < 0)) = -x

f(0) = 42
f(x::{x > 0}) =  x
f(x::{x < 0}) = -x

f(0) = 42
f(x; x > 0) =  x
f(x; x < 0) = -x

f(0) = 42
f(x >: x > 0) =  x
f(x >: x < 0) = -x

f(0) = 42
f(x::where(x > 0)) =  x
f(x::where(x < 0)) = -x

f(0) = 42
f(x::domain(x > 0)) =  x
f(x::domain(x < 0)) = -x

f(0) = 42
f(x -- x > 0) =  x
f(x -- x < 0) = -x

f(0) = 42
f(x~ x > 0) =  x
f(x~ x < 0) = -x

f(0) = 42
f(@st x x > 0) =  x
f(@st x x < 0) = -x

f(0) = 42
f(x for x > 0) =  x
f(x for x < 0) = -x

f(0) = 42
f({x for x > 0}) =  x
f({x for x < 0}) = -x

f(0) = 42
f({x; x > 0}) =  x
f({x; x < 0}) = -x

f(0) = 42
f(gaurd(x > 0, x)) =  x
f(gaurd(x < 0, x)) = -x

f(0) = 42
f((where(x > 0); x)) =  x
f((where(x < 0); x)) = -x

f(0) = 42
f((@where x > 0; x)) =  x
f((@where x < 0; x)) = -x

f(0) = 42
f(x ~st~ x > 0) =  x
f(x ~st~ x < 0) = -x

f(0) = 42
f(x ~where~ x > 0) =  x
f(x ~where~ x < 0) = -x

f(0) = 42
f(x <- (x > 0)) = x
f(x <- (x < 0)) = x

f(0) = 42
f(x => x > 0) = x
f(x => x < 0) = x
