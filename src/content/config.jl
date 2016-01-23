export localips, launch

@init global const port = get(ENV, "BLINK_PORT", rand(2_000:10_000))

const ippat = r"([0-9]+\.){3}[0-9]+"

@unix_only localips() =
  map(IPv4, readlines(`ifconfig` |>
                      `grep -Eo $("inet (addr:)?$(ippat.pattern)")` |>
                      `grep -Eo $(ippat.pattern)` |>
                      `grep -v $("127.0.0.1")`))

# Browser Window

@osx_only     launch(x) = run(`open $x`)
@linux_only   launch(x) = run(`xdg-open $x`)
@windows_only launch(x) = run(`cmd /C start $x`)

localurl(p::Page) = "http://127.0.0.1:$port/$(id(p))"

launch(p::Page) = (launch(localurl(p)); p)
