import BinDeps

rm′(f) = (isdir(f) || isfile(f)) && rm(f, recursive = true)

const version = "1.7.10"


function install()
  dir = resolve("Blink", "deps")
  if is_apple()
    const _icons = resolve("Blink", "res/julia-icns.icns")
  end
  mkpath(dir)
  cd(dir) do
    download(x) = run(BinDeps.download_cmd(x, basename(x)))

    download("http://junolab.s3.amazonaws.com/blink/julia.png")

    if is_apple()
      rm′("Julia.app")
      file = "electron-v$version-darwin-x64.zip"
      download("https://github.com/electron/electron/releases/download/v$version/$file")
      run(`unzip -q $file`)
      rm(file)
      run(`mv Electron.app Julia.app`)
      run(`mv Julia.app/Contents/MacOS/Electron Julia.app/Contents/MacOS/Julia`)
      run(`sed -i.bak 's/Electron/Julia/' Julia.app/Contents/Info.plist`)
      run(`cp $_icons Julia.app/Contents/Resources/electron.icns`)
      run(`touch Julia.app`)  # Apparently this is necessary to tell the OS to double-check for the new icons.
    end

    if is_windows()
      rm′("atom")
      arch = Int == Int64 ? "x64" : "ia32"
      file = "electron-v$version-win32-$arch.zip"
      download("https://github.com/electron/electron/releases/download/v$version/$file")
      run(`7z x $file -oatom`)
      rm(file)
    end

    if is_linux()
      rm′("atom")
      arch = Int == Int64 ? "x64" : "ia32"
      file = "electron-v$version-linux-$arch.zip"
      download("https://github.com/electron/electron/releases/download/v$version/$file")
      run(`unzip -q $file -d atom`)
      rm(file)
    end
  end
end

folder() = resolve("Blink", "deps")

isinstalled() = isdir(folder())

remove() = rm(folder(), recursive = true)
