load("pattern/req.jl")
req("pattern/recode.jl")
req("pattern/test/utils.jl")



# unite(x, x) = x,
#     Subs(>=, {}[])
px, py, pz = @qpat x x x
p, s = unite_ps(px,py)
@test egal(p,pz)
@test (egal(px, pz)) == true
@test (egal(py, pz)) == true
@test (egal(px, py)) == true
@test (s.disproved_p_ge_x) == false

# reverse:
# unite(x, x) = x,
#     Subs(>=, {}[])
px, py, pz = @qpat x x x
p, s = unite_ps(px,py)
@test egal(p,pz)
@test (egal(px, pz)) == true
@test (egal(py, pz)) == true
@test (egal(px, py)) == true
@test (s.disproved_p_ge_x) == false


# unite(x, y) = y,
#     Subs(>=, {
#         x => y, 
#     }[])
px, py, pz = @qpat x y y
p, s = unite_ps(px,py)
@test egal(p,pz)
@test (egal(px, pz)) == false
@test (egal(py, pz)) == true
@test (egal(px, py)) == false
@test (s.disproved_p_ge_x) == false

# reverse:
# unite(y, x) = x,
#     Subs(>=, {
#         y => x, 
#     }[])
px, py, pz = @qpat y x x
p, s = unite_ps(px,py)
@test egal(p,pz)
@test (egal(px, pz)) == false
@test (egal(py, pz)) == true
@test (egal(px, py)) == false
@test (s.disproved_p_ge_x) == false


# unite(x, 1) = 1,
#     Subs(>=, {
#         x => 1, 
#     }[])
px, py, pz = @qpat x 1 1
p, s = unite_ps(px,py)
@test egal(p,pz)
@test (egal(px, pz)) == false
@test (egal(py, pz)) == true
@test (egal(px, py)) == false
@test (s.disproved_p_ge_x) == false

# reverse:
# unite(1, x) = 1,
#     Subs(  , {
#         x => 1, 
#     }[])
px, py, pz = @qpat 1 x 1
p, s = unite_ps(px,py)
@test egal(p,pz)
@test (egal(px, pz)) == true
@test (egal(py, pz)) == false
@test (egal(px, py)) == false
@test (s.disproved_p_ge_x) == true


# unite(1, 1) = 1,
#     Subs(>=, {}[])
px, py, pz = @qpat 1 1 1
p, s = unite_ps(px,py)
@test egal(p,pz)
@test (egal(px, pz)) == true
@test (egal(py, pz)) == true
@test (egal(px, py)) == true
@test (s.disproved_p_ge_x) == false

# reverse:
# unite(1, 1) = 1,
#     Subs(>=, {}[])
px, py, pz = @qpat 1 1 1
p, s = unite_ps(px,py)
@test egal(p,pz)
@test (egal(px, pz)) == true
@test (egal(py, pz)) == true
@test (egal(px, py)) == true
@test (s.disproved_p_ge_x) == false


# unite(1, 5) = pat(nonematch),
#     Subs(  , {}[])
px, py, pz = @qpat 1 5 pat(nonematch)
p, s = unite_ps(px,py)
@test egal(p,pz)
@test (egal(px, pz)) == false
@test (egal(py, pz)) == false
@test (egal(px, py)) == false
@test (s.disproved_p_ge_x) == true

# reverse:
# unite(5, 1) = pat(nonematch),
#     Subs(  , {}[])
px, py, pz = @qpat 5 1 pat(nonematch)
p, s = unite_ps(px,py)
@test egal(p,pz)
@test (egal(px, pz)) == false
@test (egal(py, pz)) == false
@test (egal(px, py)) == false
@test (s.disproved_p_ge_x) == true


# unite(x, z~(y,1,)) = z~(y,1,),
#     Subs(>=, {
#         z~(y,1,) => z~(y,1,), 
#         x => z~(y,1,), 
#     }[])
px, py, pz = @qpat x z~(y,1,) z~(y,1,)
p, s = unite_ps(px,py)
@test egal(p,pz)
@test (egal(px, pz)) == false
@test (egal(py, pz)) == true
@test (egal(px, py)) == false
@test (s.disproved_p_ge_x) == false

# reverse:
# unite(z~(y,1,), x) = x~(y,1,),
#     Subs(  , {
#         z~(y,1,) => x~(y,1,), 
#         x => x~(y,1,), 
#     }[])
px, py, pz = @qpat z~(y,1,) x x~(y,1,)
p, s = unite_ps(px,py)
@test egal(p,pz)
@test (egal(px, pz)) == false
@test (egal(py, pz)) == false
@test (egal(px, py)) == false
@test (s.disproved_p_ge_x) == true


# unite(x~(y,1,), z~(5,1,)) = z~(5,1,),
#     Subs(>=, {
#         z~(5,1,) => z~(5,1,), 
#         x~(y,1,) => z~(5,1,), 
#         y => 5, 
#     }[])
px, py, pz = @qpat x~(y,1,) z~(5,1,) z~(5,1,)
p, s = unite_ps(px,py)
@test egal(p,pz)
@test (egal(px, pz)) == false
@test (egal(py, pz)) == true
@test (egal(px, py)) == false
@test (s.disproved_p_ge_x) == false

# reverse:
# unite(z~(5,1,), x~(y,1,)) = x~(5,1,),
#     Subs(  , {
#         z~(5,1,) => x~(5,1,), 
#         x~(y,1,) => x~(5,1,), 
#         y => 5, 
#     }[])
px, py, pz = @qpat z~(5,1,) x~(y,1,) x~(5,1,)
p, s = unite_ps(px,py)
@test egal(p,pz)
@test (egal(px, pz)) == false
@test (egal(py, pz)) == false
@test (egal(px, py)) == false
@test (s.disproved_p_ge_x) == true


# unite(x, y~(1,x,)) = y~(1,y,),
#     Subs(>=, {
#         y~(1,x,) => y~(1,x,), 
#         x => y~(1,x,), 
#     }[])
px, py, pz = @qpat x y~(1,x,) y~(1,y,)
p, s = unite_ps(px,py)
@test egal(p,pz)
@test (egal(px, pz)) == false
@test (egal(py, pz)) == false
@test (egal(px, py)) == false
@test (s.disproved_p_ge_x) == false

# reverse:
# unite(y~(1,x,), x) = x~(1,x,),
#     Subs(  , {
#         y~(1,x,) => x~(1,x,), 
#         x => x~(1,x,), 
#     }[])
px, py, pz = @qpat y~(1,x,) x x~(1,x,)
p, s = unite_ps(px,py)
@test egal(p,pz)
@test (egal(px, pz)) == false
@test (egal(py, pz)) == false
@test (egal(px, py)) == false
@test (s.disproved_p_ge_x) == true
