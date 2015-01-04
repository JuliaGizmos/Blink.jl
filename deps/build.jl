rm′(f) = (isdir(f) || isfile(f)) && rm(f, recursive = true)

version = "0.20.3"

download(x) = run(`curl -LO $x`)

download("http://junolab.s3.amazonaws.com/atom-shell/julia.png")

@osx_only begin
  rm′("Julia.app")
  shell = "atom-shell-mac-$version.zip"
  download("http://junolab.s3.amazonaws.com/atom-shell/$shell")
  run(`unzip $x`)
  rm(shell)
end

@windows_only begin
  rm′("atom")
  shell = "atom-shell-v$version-win32-ia32.zip"
  download("https://github.com/atom/atom-shell/releases/download/v$version/$shell")
  unzip(shell, "atom")
  run(`7z x $shell -oatom`)
  rm(shell)
end

@linux_only begin
  rm′("atom")
  arch = Int == Int64 ? "x64" : "ia32"
  shell = "atom-shell-v$version-linux-$arch.zip"
  download("https://github.com/atom/atom-shell/releases/download/v$version/$shell")
  run(`unzip $shell -d atom`)
  #rm(shell)
end
