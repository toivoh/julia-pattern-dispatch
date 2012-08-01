
require("pattern/node.jl")

egalguard(args::Node...) = Guard(Egal(args...))
p_apply(f::Function, args...) = Apply(Atom(f), args...)

atomnet(arg::Node, value) =       egalguard(arg, Atom(value))
varnet(arg::Node, name::Symbol) = egalguard(arg, Variable(name))

typenet(arg::Node, T) =           Guard(Isa(arg, Atom(T)))

function tuplenet(arg::Node, ps...)
    n = length(ps)
    arg = Gate(arg, Guard(Isa(arg, Atom(Tuple))))
    arg = Gate(arg, Guard(Egal(p_apply(length, arg), Atom(n))))
    
    if n==0
        return arg.guard
    end
    NodeSet{Node}({p(p_apply(ref, arg, Atom(k))) for (p,k) = enumerate(ps)}...)
end

atompat(value) = arg->atomnet(arg, value)
varpat(name::Symbol) = arg->varnet(arg, name)
typepat(T) = arg->typenet(arg, T)
tuplepat(ps...) = arg->tuplenet(arg, ps...)
