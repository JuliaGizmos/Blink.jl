import BinDeps

rm′(f) = (isdir(f) || isfile(f)) && rm(f, recursive = true)

const version = "0.35.2"

function install()
  dir = resolve("Blink", "deps")
  mkpath(dir)
  cd(dir) do
    download(x) = run(BinDeps.download_cmd(x, basename(x)))

    download("http://junolab.s3.amazonaws.com/blink/julia.png")

    @osx_only begin
      rm′("Julia.app")
      shell = "electron-v$version-darwin-x64.zip"
      download("https://junolab.s3.amazonaws.com/blink/$shell")
      run(`unzip -q $shell`)
      rm(shell)
    end

    @windows_only begin
      rm′("atom")
      arch = Int == Int64 ? "x64" : "ia32"
      shell = "electron-v$version-win32-$arch.zip"
      download("https://github.com/atom/electron/releases/download/v$version/$shell")
      run(`7z x $shell -oatom`)
      rm(shell)
    end

    @linux_only begin
      rm′("atom")
      arch = Int == Int64 ? "x64" : "ia32"
      shell = "electron-v$version-linux-$arch.zip"
      download("https://github.com/atom/electron/releases/download/v$version/$shell")
      run(`unzip -q $shell -d atom`)
      rm(shell)
    end
  end
end
