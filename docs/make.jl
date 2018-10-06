using Documenter, Blink

makedocs(
    modules = [Blink],
    format = :html,
    sitename = "Blink",
    pages = [
        "index.md",
        #"Page title" => "page2.md",
        #"Subsection" => [
        #    ...
        #]
    ],
)
