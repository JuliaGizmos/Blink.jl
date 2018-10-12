using Documenter, Blink

makedocs(
    modules = [Blink],
    format = :html,
    sitename = "Blink",
    pages = [
        "index.md",
        "guide.md",
        "Communication" => "communication.md",
        "api.md",
        #"Subsection" => [
        #    ...
        #]
    ],
)

#deploydocs(
#    repo = "github.com/NHDaly/Blink.jl.git",
#    julia = "1.0"
#)
