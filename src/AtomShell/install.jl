import BinDeps

rm′(f) = (isdir(f) || isfile(f)) && rm(f, recursive = true)

const version = "4.0.4"

folder() = normpath(joinpath(@__FILE__, "../../../deps"))

@static if Sys.isapple()
    uninstall() = map(rm′, filter(x -> !endswith(x, "build.jl"), readdir(folder())))
else
    uninstall() = rm′(joinpath(folder(), "atom"))
end

isinstalled() = Sys.isapple() ?
    isfile(joinpath(folder(), "version")) :
    isdir(joinpath(folder(), "atom"))


function install()
  dir = folder()
  if Sys.isapple()
    _icons = normpath(joinpath(@__FILE__, "../../../res/julia-icns.icns"))
  end
  !isdir(dir) && mkpath(dir)
  uninstall()
  cd(dir) do
    download(x) = run(BinDeps.download_cmd(x, basename(x)))

    download("http://junolab.s3.amazonaws.com/blink/julia.png")

    if Sys.isapple()
      file = "electron-v$version-darwin-x64.zip"
      download("https://github.com/electron/electron/releases/download/v$version/$file")
      run(`unzip -q $file`)
      rm(file)
      if isdir("Julia.app") # Issue # 178
          rm("Julia.app", recursive=true)
      end
      run(`mv Electron.app Julia.app`)
      run(`mv Julia.app/Contents/MacOS/Electron Julia.app/Contents/MacOS/Julia`)
      run(`sed -i.bak 's/Electron/Julia/' Julia.app/Contents/Info.plist`)
      run(`cp $_icons Julia.app/Contents/Resources/electron.icns`)
      run(`touch Julia.app`)  # Apparently this is necessary to tell the OS to double-check for the new icons.
    end

    if Sys.iswindows()
       arch = Int == Int64 ? "x64" : "ia32"
       file = "electron-v$version-win32-$arch.zip"
       download("https://github.com/electron/electron/releases/download/v$version/$file")
       zipper = joinpath(Base.Sys.BINDIR, "7z.exe")
       if !isfile(zipper)
           #=
           This is likely built with cygwin, which includes its own version of 7z.
           But if we unzip with cmd = Cmd(`$(fwhich("bash.exe")) 7z x $file -oatom`)
           The resulting files would not be windows executable.
           So we want the 7z.exe included with a binary download of Julia.
           The PATH environment variable likely includes to the locally built
           Julia, so instead we look in the default Julia binary location and
           pick the latest version.
           =#
           juliafolders = filter(readdir(ENV["LOCALAPPDATA"])) do f
                                     startswith(f, "Julia-")
              end
           juliaversions = VersionNumber.([replace(f, "Julia-" => "") for f in juliafolders])
           i = findlast(isequal(maximum(juliaversions)), juliaversions)
           zipper = joinpath(ENV["LOCALAPPDATA"], juliafolders[i], "bin", "7z.exe")
           isfile(zipper) || error("could not find $zipper. Try also installing a binary version of Julia.")
        end
        cmd = Cmd([zipper, "x", file, "-oatom"])
        run(cmd)
        rm(file)
    end

    if Sys.islinux()
      arch = Int == Int64 ? "x64" : "ia32"
      file = "electron-v$version-linux-$arch.zip"
      download("https://github.com/electron/electron/releases/download/v$version/$file")
      run(`unzip -q $file -d atom`)
      rm(file)
    end
  end
end
