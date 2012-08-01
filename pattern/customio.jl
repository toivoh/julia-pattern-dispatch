
abstract CustomIO <: IO

##  Methods to redirect strings etc output to a CustomIO to one place ##
print(io::CustomIO, c::Char) = print_char(io, c)
for S in [:ASCIIString, :UTF8String, :RopeString, :String]
    @eval print(io::CustomIO, s::($S)) = print_str(io, s)
end
show(io::CustomIO, s::Symbol) = print(io, string(s))

print_str(io::CustomIO, s::String) = (for c in s; print_char(io, c); end)


show(io::CustomIO, x::Float64) = print(io, sshow(x))
show(io::CustomIO, x::Float32) = print(io, sshow(x))
# fix to avoid jl_show_any on CustomIO (segfaults)
function show(io, x) 
    io::IO
    if isa(io, CustomIO)
#        print(io, sshow(x))
        default_show(io, x)
    elseif isa(io, IOStream)
        ccall(:jl_show_any, Void, (Any, Any,), io, x)
    else
        error("unimplemented!")
    end
end


# works as long as this calls jl_show_any...
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
    print(io, sshow(T), tuple(values...))
end
