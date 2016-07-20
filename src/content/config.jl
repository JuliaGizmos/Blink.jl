export localips, launch

@init global const port = get(ENV, "BLINK_PORT", rand(2_000:10_000))

const ippat = r"([0-9]+\.){3}[0-9]+"

@static if is_unix()
    localips() = map(IPv4, readlines(`ifconfig` |>
                      `grep -Eo $("inet (addr:)?$(ippat.pattern)")` |>
                      `grep -Eo $(ippat.pattern)` |>
                      `grep -v $("127.0.0.1")`))
end

# Browser Window

@static if is_apple()
    launch(x) = run(`open $x`)
elseif is_linux()
    launch(x) = run(`xdg-open $x`)
elseif is_windows()
    launch(x) = run(`cmd /C start $x`)
end

localurl(p::Page) = "http://127.0.0.1:$port/$(id(p))"

launch(p::Page) = (launch(localurl(p)); p)
