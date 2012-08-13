
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

macro immutable(ex)
    @expect is_expr(ex, :type, 2)
    typesig, defs = ex.args[1], ex.args[2]
    typespec = is_expr(typesig, :comparison) ? typesig.args[1] : typesig
    typename = (is_expr(typespec,:curly) ? typespec.args[1] : typespec)::Symbol

    @expect is_expr(defs, :block)
    fieldsf = filter(ex->isa(ex, Symbol),
              {is_expr(ex, doublecolon) ? ex.args[1] : ex for ex in defs.args})
    fields = Symbol[]
    for field in fieldsf; push(fields, field); end

    defs = quote
        ($defs.args...)
        ($typename)($fields...) = ($quot(immcanon))(new($fields...))
    end
    esc(expr(:type, typesig, defs))
end

end
