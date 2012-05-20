julia-pattern-dispatch v0.0
===========================
Toivo Henningsson

This package is an attempt to support method dispatch in Julia based on pattern matching. This is meant to be a generalization of Julia's multiple dispatch; though some of Julia's dispatch features are not implemented yet, e g varargs.

Installation
------------
Download the source and copy the `pattern/` subdirectory into your source files' directory.

Examples
--------
These examples are gathered in `test/test.jl`.

Pattern methods are defined using the `@pattern` macro.
The method with the most specific pattern that matches the given arguments
is invoked, with variable values needed to match assigned to the corresponding variables.

Signatures can contain a mixture of variables and literals:

    load("pattern/pdispatch.jl")

    @pattern f(x) =  x
    @pattern f(2) = 42

    print({f(x) for x=1:4})

prints

    {1, 42, 3, 4}

Signatures can also contain patterns of tuples and vectors:

    @pattern f2({x,y}) = x*y
    @pattern f2(x) = nothing
 
    ==> f2({2,5}) = 10, f2({4,3}) = 12
        f2(1) = f2("hello") = f2({1}) = f2({1,2,3}) = nothing

Repeated arguments are allowed:

    @pattern eq(x,x) = true
    @pattern eq(x,y) = false

    ==> eq(1,1) = true
        eq(1,2) = false

Pattern variables can of course also be qualified by type,
e g `@pattern f((x::Int,y::Float))` matches only on `(Int,Float)` tuples.

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

There is also an inline syntax to match a single pattern:

    load("pattern/ifmatch.jl")

    for k=1:4
        print("k = $k: ")
        m::Bool = @ifmatch let {x,2}={k,k}
            println("x = $x")
        end
        if !m
            println("no match")
        end
    end

prints

    k = 1: no match
    k = 2: x = 2
    k = 3: no match
    k = 4: no match

The `@ifmatch let` block is executed only if the pattern in the left hand side of `=` matches the value in the right hand side.
The value of `@ifmatch let` is `true` if the pattern matches, and false otherwise.

Feaures
-------
* Patterns can consist of values, variables, tuples, and arrays
* Variables can be qualified by type
* Repeated variables allowed in patterns
* Generation of pattern matching code for individual patterns
* Dispatches on most specific pattern
* Warning when addition of a pattern method causes dispatch ambiguity

Aim
---
* Provide a powerful and intuitive dispatch mechanism based on pattern matching
* Support a superset of Julia's multiple dispatch
* Generate fast matching code for a given collection of pattern method signatures
* Allow Julia's optimizations such as type inference to work with pattern dispatch

Planned/possible features
----------------
* Pattern matching on struct-like types
* User definable pattern matching on user defined types
* Play well with type inference
* Leverage method dispatch to reduce matching overhead
* Generate merged matching code for multiple similar patterns
* Varargs: matching on e g `(x, ys..., z)` and `{x, ys..., z}`
* Allow to qualify variables by domains other than type, e g all values that compare equal to 2, perhaps ranges, ...

Limitations
-----------
* Not yet as fast as it could be
* Not yet terribly tested
* No support for type parameters a la `f{T}(...)`

Matching model
--------------
* A pattern can be built from variables, composites (tuples, arrays, structs,...) and atoms (simple values).
* A value can be built from composites and atoms.
* A pattern matches a set of values; but only one value for a given assignment of its variables.
* Patterns, especially variables, can be constrained by _domains_: sets of values. (E g all values of a given type)
* Domains for composites should be separable: they should be possible to express as a condition on the characteristics
* of the container itself combined with independent conditions on its elements.
