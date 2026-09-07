# JSON.jl compatibility

import JSON

@static if isdefined(JSON, :JSONStyle) # JSON.jl >= 1
    struct BlinkSerialization <: JSON.JSONStyle end
    JSON.lower(::BlinkSerialization, x::AbstractFloat) = isfinite(x) ? x : nothing

    jsonstring(x) = JSON.json(x; style = BlinkSerialization())
    jsonprint(io::IO, x) = JSON.json(io, x; style = BlinkSerialization())

    jsonparse(x) = JSON.parse(x; dicttype = Dict{String, Any})
else
    jsonstring(x) = JSON.json(x)
    jsonprint(io::IO, x) = JSON.print(io, x)
    jsonparse(x) = JSON.parse(x)
end
