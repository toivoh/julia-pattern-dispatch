julia-pattern-dispatch v0.0
===========================
Toivo Henningsson

This package is an attempt to support method dispatch in Julia based on pattern matching. This is meant to be a generalization of Julia's multiple dispatch, though some of Julia's dispatch features are not implemented yet, e g varargs.

Examples
--------
Pattern functions are defined using the `@pattern` macro.
The most specific pattern that matches the given arguments is invoked.
These examples are gathered in `test/test.jl`.

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

A warning is printed if a new definition makes dispatch ambiguous:
    
    @pattern ambiguous((x,y),z) = 2
    @pattern ambiguous(x,(1,z)) = 3

prints

    Warning: New @pattern method h(pvar(:x),(1,pvar(:z)))
             is ambiguous with   h((pvar(:x),pvar(:y)),pvar(:z))
             Make sure h((pvar(:x),pvar(:y)),(1,pvar(:z))) is defined first

Fun fact:

    @pattern f3(x,{1,x}) = 1
    @pattern f3(x,x)     = 2

does not print an ambiguity warning, since there is no overlap between finite patterns. The infinitely nested sequence `x={1,{1,{1,...}}}` could be considered to match both, however.
