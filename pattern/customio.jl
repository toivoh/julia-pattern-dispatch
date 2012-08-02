
require("pattern/utils.jl") # quot

abstract CustomIO <: IO

print_str(io::CustomIO, s::String) = (for c in s; print_char(io, c); end)

##  Methods to redirect strings etc output to a RecorderIO to one place ##
# Use @custimio MyIO on a new type MyIO <: CustomIO
macro customio(Tsym)
    TSym = esc(Tsym)
    Ts = {ASCIIString, UTF8String, RopeString, String}
    print_str_defs = { 
        :(print(io::($Tsym), s::($(quot(S)))) = print_str(io, s)) for S in Ts}
    quote
        print(io::($Tsym), x::VersionNumber) = print(io, string(x))
        print(io::($Tsym), c::Char) = print_char(io, c)
        ($print_str_defs...)
    end
end

## Take care of further quirks ##
write(io::CustomIO, s::ASCIIString) = print_str(io, s)
show(io::CustomIO, s::Symbol) = print(io, string(s))

# fix to avoid jl_show_any on CustomIO (segfaults)
function show(io, x) 
    io::IO
    if isa(io, IOStream)
        ccall(:jl_show_any, Void, (Any, Any,), io, x)
    else
        default_show(io, x)
    end
#     if isa(io, CustomIO)
#         default_show(io, x)
#     elseif isa(io, IOStream)
#         ccall(:jl_show_any, Void, (Any, Any,), io, x)
#     else
#         error("unimplemented!")
#     end
end


# works as long as this calls jl_show_any...
# todo: fall back on jl_show_any here instead?
default_show(io::IO, x::Union(Type,Function)) = print(io, sshow(x))

default_show(io::IO, x) = default_show(io, typeof(x), x)

const null_symbol = symbol("")

 # works as long as it invokes jl_show_any...
default_show(io, T, x) = print(io, sshow(x))
function default_show(io, T::CompositeKind, x)
    fields = filter(x->(x!=null_symbol), [T.names...])
    values = {}
    for field in fields
        try 
            push(values, getfield(x, field))
        catch err
            error("default_show: Unable to access field \"$field\" in $(typeof(x))")
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
