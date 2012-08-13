
module Immutable
export @immutable

import Base.*
load("utils.jl")
load("staged.jl")

function immcanon{T}(x::T)
    dict = get_immdict(x)
    fields = get_all_fields(x)
    if has(dict, fields) dict[fields]
    else                 dict[fields] = x
    end
end

@staged function get_all_fields(x)
    expr(:tuple, { :(x.($quot(name))) for name in x.names })
end
@staged function get_immdict(x)
    quot(ObjectIdDict())
end

record_fields!(fields::Vector{Symbol}, ex::Symbol) = (push(fields,ex); nothing)
function record_fields!(fields::Vector{Symbol}, ex::Expr)
    if (ex.head === :block) 
        for arg in ex.args; record_fields!(fields, arg); end
    elseif (ex.head === doublecolon) 
        record_fields!(fields, ex.args[1])
    end
end
record_fields!(fields::Vector{Symbol}, ex) = nothing

macro immutable(ex)
    @expect is_expr(ex, :type, 2)
    typesig, defs = ex.args[1], ex.args[2]
#    typespec = is_expr(typesig, :comparison) ? typesig.args[1] : typesig
    typespec = is_expr(typesig, :(<:)) ? typesig.args[1] : typesig
    @show typespec
    typename = (is_expr(typespec,:curly) ? typespec.args[1] : typespec)::Symbol

    @expect is_expr(defs, :block)
    fields = Symbol[]
    record_fields!(fields, defs)

    defs = quote
        ($defs.args...)
        ($typename)($fields...) = ($quot(immcanon))(new($fields...))
    end
    esc(expr(:type, typesig, defs))
end

end
