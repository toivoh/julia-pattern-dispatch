

load("pattern/req.jl")
req("pattern/utils.jl")
req("pattern/composites.jl")
req("pattern/recode.jl")
req("pattern/pmatch.jl")


function split_fdef(fdef::Expr)
    @expect (fdef.head == :function) || (fdef.head == :(=))
    @expect length(fdef.args) == 2
    signature, body = tuple(fdef.args...)
    @expect is_expr(signature, :call)
    @expect length(signature.args) >= 1
    (signature, body)
end
split_fdef(f::Any) = error("split_fdef: expected function definition, got\n$f")


# -- @patmethod ---------------------------------------------------------------

type PatternMethod
    pattern
    body

    dispfun::Function
end
function patmethod(pattern, body)
    dispfun = create_patmethod_dispfun(pattern, body)
    PatternMethod(pattern, body, dispfun)
end

function create_patmethod_dispfun(pattern, body)
    eval(code_patmethod_dispfun(pattern, body))
end
function code_patmethod_dispfun(pattern, body)
    argsname = gensym("args")
    pmc=PMContext(:(false,nothing))
    code_pmatch(pmc, pattern,argsname)
    push(pmc.code, :(true, ($body)))

    :( (($argsname)...)->(begin
        ($pmc.code...)        
    end))
end


macro patmethod(fdef)
    code_patmethod(fdef)
end
function code_patmethod(fdef)
    signature, body = split_fdef(fdef)
    @expect is_expr(signature, :call)
    pattern_ex = quotedtuple(signature.args[2:end])

    pattern_ex = recode_pattern_ex(pattern_ex)

    # evaluates the pattern expression inline
    :( patmethod(($pattern_ex), ($quotevalue(body))) )
end


# -- @pattern -----------------------------------------------------------------

type PatternMethodTable
    fname::Symbol
    methods::Vector{PatternMethod}

    PatternMethodTable(fname::Symbol) = new(fname, PatternMethod[])
end

#add(mt::PatternMethodTable, m::PatternMethod) = push(mt.methods, m)
function add(mt::PatternMethodTable, m::PatternMethod)    
    ms = mt.methods
    n = length(ms)

    # insert the pattern in ascending topological order, as late as possible
    i = n+1
    for k=1:n
        if pattern_le(m.pattern, ms[k].pattern)
            if pattern_ge(m.pattern, ms[k].pattern)
                # equal signature ==> replace
                mt.methods[k] = m
                return
            else
                i = k
                break
            end
        end
    end

    ms = mt.methods = PatternMethod[ms[1:i-1]..., m, ms[i:n]...]

    # warn if new signature is ambiguous with an old one
    for m0 in ms
        lb, s = unify(m0.pattern, m.pattern)
        if !(is(lb,nonematch) || any({pattern_eq(lb,mk.pattern) for mk in ms}))
            # todo: 
            #   o disambiguate pvars in lb (might have same name)
            #   o print x::Int instead of pvar(x,Int)?    
            println("Warning: New @pattern method ", mt.fname, m.pattern)
            println("         is ambiguous with   ", mt.fname, m0.pattern)
            println("         Make sure ", mt.fname, lb, " is defined first")
        end
    end

    nothing
end


function dispatch(mt::PatternMethodTable, args::Tuple)
    for m in mt.methods
        matched, result = m.dispfun(args...)
        if matched;  return result;  end
    end
    error("no dispatch found for pattern function $(m.fname)$args")
end


const __patmethod_tables = Dict{Function,PatternMethodTable}()

macro pattern(fdef)
    code_pattern_fdef(fdef)
end
function code_pattern_fdef(fdef)
    method_ex = code_patmethod(fdef)

    signature, body = split_fdef(fdef)
    fname = signature.args[1]
    qfname = quotevalue(fname)
    @gensym fun mtable
    quote
        ($fun) = nothing
        try
            ($fun) = ($fname)
        end
        if is(($fun), nothing)
            ($mtable) = PatternMethodTable($qfname)
#            const ($fname) = create_pattern_function(($mtable))
            const ($fname) = (args...)->dispatch(($mtable), args)
            __patmethod_tables[$fname] = ($mtable)
        else
            if !(isa(($fun),Function) && has(__patmethod_tables, ($fun)))
                error("\nin @pattern method definition: ", ($string(fname)), 
                " is not a pattern function")
            end
            ($mtable) = __patmethod_tables[$fun]
        end
        add(($mtable), ($method_ex))
    end
end
