port() = get(ENV, "BLINK_PORT", 8000)

const ippat = r"([0-9]+\.){3}[0-9]+"

@unix_only localips() =
  map(IPv4, readlines(`ifconfig` |>
                      `grep -Eo $("inet (addr:)?$(ippat.pattern)")` |>
                      `grep -Eo $(ippat.pattern)` |>
                      `grep -v $("127.0.0.1")`))
