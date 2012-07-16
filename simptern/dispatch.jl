
require("simptern/pattern.jl")


# -- @patmethod ---------------------------------------------------------------

type PatternMethod
    signature::Pattern
    body

    dispfun::Function
end
patmethod(rawsig, body) = patmethod(pattern(rawsig), body)
function patmethod(signature::Pattern, body)
    dispfun = create_patmethod_dispfun(signature, body)
    PatternMethod(signature, body, dispfun)
end

function create_patmethod_dispfun(signature::Pattern, body)
    eval(code_patmethod_dispfun(signature, body))
end
function code_patmethod_dispfun(signature::Pattern, body)   
    argname = get_argname(signature)
    code = code_match(signature, :(false,nothing))
    :( (($argname)...)->(begin
        ($code)
        (true, ($body))
    end))
end


# -- @patmethod ---------------------------------------------------------------

macro patmethod(fdef)
    code_patmethod(fdef)
end
function code_patmethod(fdef)
    fsig, body = split_fdef(fdef)
    @expect is_expr(fsig, :call)

    signature_ex = expr(:tuple, fsig.args[2:end])
    signature_ex = recode_patex(signature_ex)

    # evaluates the signature expression inline
    :( patmethod(($signature_ex), ($quot(body))) )
end


# -- PatternMethodTable -------------------------------------------------------

type PatternMethodTable
    fname::Symbol
    methods::Vector{PatternMethod}

    PatternMethodTable(fname::Symbol) = new(fname, PatternMethod[])
end

function add(mt::PatternMethodTable, m::PatternMethod)    
    ms = mt.methods
    n = length(ms)

    sig = m.signature 

    # insert signature in ascending topological order, as late as possible
    i = findfirst({{feas(sig) <= feas(mk.signature) for mk in ms}..., true})
    if (i <= n) && (feas(sig) == feas(ms[i].signature))
        mt.methods[i] = m  # equal signature ==> replace
        return
    end
    ms = mt.methods = PatternMethod[ms[1:i-1]..., m, ms[i:n]...]

    # warn if new signature is ambiguous with an old one
    for m0 in ms
        sig0 = m0.signature
        lb = unify(feas(sig0), feas(sig))
        if !(nevermatches(lb) || any({lb == feas(mk.signature) for mk in ms}))
            # todo: 
            #   o disambiguate pvars in lb (might have same name)
            println("Warning: New @pattern method ", mt.fname, sig)
            println("         is ambiguous with   ", mt.fname, sig0)
            println("         Make sure           ", mt.fname, lb)
            println(" is defined first.")
        end
    end

    nothing
end


function dispatch(mt::PatternMethodTable, args::Tuple)
    for m in mt.methods
        matched, result = m.dispfun(args...)
        if matched;  return result;  end
    end
    error("no dispatch found for pattern function $(mt.fname)$args")
end


const __patmethod_tables = Dict{Function,PatternMethodTable}()

macro pattern(fdef)
    code_pattern_fdef(fdef)
end
function code_pattern_fdef(fdef)
    method_ex = code_patmethod(fdef)

    fsig, body = split_fdef(fdef)
    fname = fsig.args[1]
    @gensym fun mtable
    quote
        ($fun) = nothing
        try
            ($fun) = ($fname)
        end
        if is(($fun), nothing)
            ($mtable) = PatternMethodTable($quot(fname))
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
