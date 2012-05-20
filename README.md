julia-pattern-dispatch v0.0
===========================
Toivo Henningsson

This package is an attempt to support method dispatch in Julia based on pattern matching. This is meant to be a generalization of Julia's multiple dispatch; though some of Julia's dispatch features are not implemented yet, e g varargs.

Examples
--------
These examples are gathered in `test/test.jl`.

Pattern functions are defined using the `@pattern` macro.
The most specific pattern that matches the given arguments is invoked.
Signatures can contain a mixture of variables and literals:

    load("pattern/pdispatch.jl")

    @pattern f(x) =  x
    @pattern f(2) = 42

    print({f(x) for x=1:4})

prints

    {1, 42, 3, 4}

Signatures can also contain patterns of tuples and vectors:

    @pattern f2({x,y}) = 1
    @pattern f2(x) = 2
 
    ==> f2({1,2}) = f2({"a",:x}) = 1
        f2(1) = f2("hello") = f2({1}) = f2({1,2,3}) = 2

Repeated arguments are allowed:

    @pattern eq(x,x) = true
    @pattern eq(x,y) = false

    ==> eq(1,1) = true
        eq(1,2) = false

Symbols in signatures are replaced by pattern variables by default (symbols in the position of function names and at the right hand side of `::` are not).
To use a preexisting value as a literal, use `staticvalue()`, which evaluates an expression at the point of definition:

    @pattern f3(staticvalue(nothing)) = 1
    @pattern f3(x) = 2

    ==> f3(nothing) = 1
        f3(1) = f3(:x) = f3("hello") = 2

A warning is printed if a new definition makes dispatch ambiguous:
    
    @pattern ambiguous((x,y),z) = 2
    @pattern ambiguous(x,(1,z)) = 3

prints

    Warning: New @pattern method ambiguous(x, (1, z,),)
             is ambiguous with   ambiguous((x, y,), z,)
             Make sure           ambiguous((x, y,), (1, z,),) is defined first.

Signatures are evaluated at the point of method definition, after replacing symbols by pattern variables. This allows to invoke another function within the signature:

    opnode(op, arg1, arg2) = {:call, op, arg1, arg2}

    @pattern undot(opnode(:.+, arg1, arg2)) = opnode(:+, undot(arg1), undot(arg2))
    @pattern undot(opnode(:.*, arg1, arg2)) = opnode(:*, undot(arg1), undot(arg2))
    @pattern undot(opnode( op, arg1, arg2)) = opnode(op, undot(arg1), undot(arg2))
    @pattern undot(n) = n

    ==> undot(opnode(:.+, :x,:y)) = {:call, :+, :x, :y}
        undot(opnode(:.*, :x,:y)) = {:call, :*, :x, :y}
        undot(opnode(:.+, :x,opnode(:.*,:y,:z))) = {:call, :+, x, {:call, :*, :y, :z}}
        undot(opnode(:-,  :x,opnode(:.*,:y,:z))) = {:call, :-, x, {:call, :*, :y, :z}}

Fun fact:

    @pattern fn(x,{1,x}) = 1
    @pattern fn(x,x)     = 2

does not print an ambiguity warning, since there is no overlap between finite patterns. The infinitely nested sequence `x={1,{1,{1,...}}}` could be considered to match both, however.
