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
    ],
)

deploydocs(
    repo = "github.com/JuliaGizmos/Blink.jl.git",
    target = "build",
    deps = nothing,
    make = nothing,
)
