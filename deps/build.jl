rm′(f) = (isdir(f) || isfile(f)) && rm(f, recursive = true)

@osx_only begin
  rm′("Julia.app")
  shell = "atom-shell-mac-0.20.3.zip"
  download("http://junolab.s3.amazonaws.com/atom-shell/$shell", shell)
  run(`unzip $shell`)
  rm(shell)
end
