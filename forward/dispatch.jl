
load("pattern/req.jl")
req("pattern/recode.jl")

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
    signature::PNode
    body

    dispfun::Function
end
function patmethod(signature::PNode, body)
    dispfun = create_patmethod_dispfun(signature, body)
    PatternMethod(signature, body, dispfun)
end

function create_patmethod_dispfun(signature::PNode, body)
    eval(code_patmethod_dispfun(signature, body))
end
function code_patmethod_dispfun(signature::PNode, body)
    argsname = gensym("args")
    vars, code = code_match(signature, argsname, :(false,nothing))
    :( (($argsname)...)->(begin
        ($code)
        (true, ($body))
    end))
end


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

#add(mt::PatternMethodTable, m::PatternMethod) = push(mt.methods, m)
function add(mt::PatternMethodTable, m::PatternMethod)    
    ms = mt.methods
    n = length(ms)

    sig = m.signature 

    # insert the signature in ascending topological order, as late as possible
    i = n+1
    for k=1:n
        if pat_le(sig, ms[k].signature)
            if pat_ge(sig, ms[k].signature)
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
        sig0 = m0.signature
#         if pat_ge(sig,sig0) || pat_le(sig, sig0)
#             continue
#         end
        lb = unite(sig0, sig)
        if !(is(lb,nonematch) || any({pat_eq(lb,mk.signature) for mk in ms}))
            # todo: 
            #   o disambiguate pvars in lb (might have same name)
            print("Warning: New @pattern method ", mt.fname)
            show_sig(sig); println()
            print("         is ambiguous with   ", mt.fname)
            show_sig(sig0); println()
            print("         Make sure           ", mt.fname) 
            show_sig(lb)
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
