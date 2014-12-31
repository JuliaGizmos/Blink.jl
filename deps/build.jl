rm′(f) = (isdir(f) || isfile(f)) && rm(f, recursive = true)

version = "0.20.3"

download(x) = run(`curl -LO $x`)

@unix_only unzip(x) = run(`unzip $x`)

@windows_only unzip(x, y) =
  run(`7z x $x -o$y`)

@osx_only begin
  rm′("Julia.app")
  shell = "atom-shell-mac-$version.zip"
  download("http://junolab.s3.amazonaws.com/atom-shell/$shell")
  unzip(shell)
  rm(shell)
end

@windows_only begin
  rm′("atom")
  shell = "atom-shell-v$version-win32-ia32.zip"
  download("https://github.com/atom/atom-shell/releases/download/v$version/$shell")
  unzip(shell, "atom")
  rm(shell)
end

@linux_only begin
  arch = Int == Int64 ? "x64" : "ia32"
  shell = "atom-shell-v$version-linux-$arch.zip"
  download("https://github.com/atom/atom-shell/releases/download/v$version/$shell")
  unzip(shell)
  rm(shell)
end
