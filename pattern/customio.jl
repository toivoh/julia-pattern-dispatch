
require("pattern/utils.jl") # quot

abstract CustomIO <: IO

# ioprint can be overriden by the CustomIO
ioprint(io::CustomIO, s::String) = (for c in s; ioprint(io, c); end)

# @customio MyIO (<: CustomIO) redirects chars/string printing to ioprint()
macro customio(Tsym)
    TSym = esc(Tsym)
    Ts = {ASCIIString, UTF8String, RopeString, String}
    ioprint_defs = { 
        :(print(io::($Tsym), s::($(quot(S)))) = ioprint(io, s)) for S in Ts}
    quote
        print(io::($Tsym), x::VersionNumber) = print(io, string(x))
        print(io::($Tsym), c::Char) = ioprint(io, c)
        ($ioprint_defs...)
    end
end

# Take care of further quirks
write(io::CustomIO, s::ASCIIString) = ioprint(io, s)
show(io::CustomIO, s::Symbol) = print(io, string(s))

# fix to avoid jl_show_any on non-IOStream (segfaults)
function show(io, x) 
    io::IO
    if isa(io, IOStream)
        # must use jl_show_any here, to handle cases
        # default_show doesn't
        ccall(:jl_show_any, Void, (Any, Any,), io, x)
    else
        default_show(io, x)
    end
end

# todo: fall back on jl_show_any here instead?
default_show(io::IO, x::Union(Type,Function)) = print(io, sshow(x))
default_show(io::IO, x) = default_show(io, typeof(x), x)
default_show(io::IO, T, x) = print(io, sshow(x))

const null_symbol = symbol("")

function default_show(io::IO, T::CompositeKind, x)
    fields = filter(x->(x!=null_symbol), [T.names...])
    values = {}
    for field in fields
        try 
            push(values, getfield(x, field))
        catch err
            error("default_show: Unable to access field \"$field\" "*
                  "in $(typeof(x))")
        end
    end
#    print(io, sshow(T), enclose("(", comma_list(values...), ")"))
    print(io, sshow(T), "("); print_comma_list(io, values...); print(io, ")")
end

function print_comma_list(io::IO, args...)
    first = true
    for arg in args
        if !first;  print(io, ", ");  end
        print(io, arg)
        first = false
    end
end
