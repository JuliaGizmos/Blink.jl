using Documenter, Blink

Blink.AtomShell.install()

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

deploydocs(
    repo = "github.com/JunoLab/Blink.jl.git",
    julia = "1.0",
    target = "build",
    deps = nothing,
    make = nothing)
