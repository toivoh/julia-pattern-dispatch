
function guards(nset::NodeSet)
    gs = {}
    for node in filter(node->isa(node, Guard), nset) push(gs, node) end
    nodeset(gs...)
end
guards(node::Node) = guards(nodeset(node))

join(sets::NodeSet...) = nodeset(union({Set{Node}(set...) for set in sets}...)...)

<=(x::NodeSet, y::NodeSet) = (join(x,y) == y)

const false_guard    = guard(atom(false))
const false_guardset = nodeset(false_guard)
is_falseguard(node::Node) = (node == false_guard) || (node == false_guardset)


# ---- PatternFunction --------------------------------------------------------

type PatternFunction
    fname::Symbol
    methods::Vector{PatternMethod}

    PatternFunction(fname::Symbol) = new(fname, PatternMethod[])
end

function add(pf::PatternFunction, m::PatternMethod)
    push(pf.methods, m)
    #addmethod(pf, m)
    eval( code_pattern_function(pf.fname, pf.methods) )
end

function addmethod(pf::PatternFunction, m::PatternMethod)
    ms = pf.methods
    n = length(ms)
    i = n+1
    for k = 1:n
        if !(guards(m.sig) >= guards(ms[k].sig)) continue end
        # equal signature ==> replace
        if   guards(m.sig) == guards(ms[k].sig) ms[k] = m; return
        else                                i = k; break
        end
    end
    pf.methods = PatternMethod[ms[1:i-1]..., m, ms[i:n]...]
    check_ambiguity(pf, m)
end

function check_ambiguity(pf::PatternFunction, m::PatternMethod)
    ms = pf.methods
    for m0 in ms
        product = join(guards(m0.sig), guards(m.sig))
        if is_falseguard(product) continue end
        if any([guards(mk.sig) == guards(product) for mk in ms]) continue end
        
        println("Warning: New @pattern method ", pf.fname, m.sig)
        println("         is ambiguous with   ", pf.fname, m0.sig)
        println("         Make sure           ", pf.fname, product,
                " is defined first.")
    end
end

# ---- @pattern ---------------------------------------------------------------

const patfun_table = Dict{Function,PatternFunction}()

get_patfun(fname::Symbol, ::Nothing) = PatternFunction(fname)
function get_patfun(fname::Symbol, f::Function)
    if !has(patfun_table, f) patfun_error(fname); end
    patfun_table[f]
end
get_patfun(fname::Symbol, f) = patfun_error(fname)
function patfun_error(fname::Symbol)
    error("\nin @pattern method definition: $fname is not a pattern function")
end

macro pattern(fdef)
    code_pattern(fdef)
end
function code_pattern(fdef)
    fname, method_ex = recode_fdef(fdef)
    
    quote
        f = nothing
        try
            f = ($esc(fname))
        end
        pf = get_patfun($quot(fname), f)
        add(pf, $method_ex)
        
        if f === nothing; patfun_table[$esc(fname)] = pf; end
    end
end
