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
