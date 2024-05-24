# Stuff to replace Lazy.jl with
function initm(ex)
    quote
        if !isdefined(@__MODULE__, :__inits__)
            const $(esc(:__inits__)) = Function[]
        end
        if !isdefined(@__MODULE__, :__init__)
            function $(esc(:__init__))()
                for f in $(esc(:__inits__))
                    f()
                end
            end
        end

        push!($(esc(:__inits__)), () -> $(esc(ex)))
        nothing
    end
end

macro init(args...)
    initm(args...)
end

macro errs(ex)
    :(
        try
            $(esc(ex))
        catch e
            showerror(stderr, e, catch_backtrace())
            println(stderr)
        end
    )
end
