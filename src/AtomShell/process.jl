using Lazy, JSON, MacroTools

hascommand(c) =
  try readall(`which $c`); true catch e false end

spawn_rdr(cmd) = spawn(cmd, Base.spawn_opts_inherit()...)

resolve(pkg, path...) =
  joinpath(Base.find_in_path(pkg, nothing), "..","..", path...) |> normpath

# node-inspector

_inspector = nothing

function inspector()
  if hascommand("node-inspector")
    global _inspector
    _inspector != nothing && process_running(_inspector) && return _inspector
    _inspector = spawn_rdr(`node-inspector`)
  end
end

function inspector(port)
  inspector()
  run(`open http://localhost:8080/debug?port=$port`)
end

# atom-shell

import Base: Process, TCPSocket

export Electron

type Electron <: Shell
  proc::Process
  sock::TCPSocket
  handlers::Dict{ASCIIString, Any}
end

Electron(proc, sock) = Electron(proc, sock, Dict())

@osx_only     const _electron = resolve("Blink", "deps/Julia.app/Contents/MacOS/Electron")
@linux_only   const _electron = resolve("Blink", "deps/atom/electron")
@windows_only const _electron = resolve("Blink", "deps", "atom", "electron.exe")
const mainjs = resolve("Blink", "src", "AtomShell", "main.js")

function electron()
  path = get(ENV, "ELECTRON_PATH", _electron)
  isfile(path) || error("Cannot find Electron. Try `AtomShell.install()`.")
  return path
end

port() = rand(2_000:10_000)

function try_connect(args...; interval = 0.01, attempts = 100)
  for i = 1:attempts
    try
      return connect(args...)
    catch e
      i == attempts && rethrow()
    end
    sleep(interval)
  end
end

function init(; debug = false)
  electron() # Check path exists
  p, dp = port(), port()
  debug && inspector(dp)
  dbg = debug ? "--debug=$dp" : []
  proc = (debug ? spawn_rdr : spawn)(`$(electron()) $dbg $mainjs port $p`)
  conn = try_connect(ip"127.0.0.1", p)
  shell = Electron(proc, conn)
  initcbs(shell)
  return shell
end

# JS Communication

import ..Blink: msg, enable_callbacks!, handlers, handle_message, active

msg(shell::Electron, m) = (JSON.print(shell.sock, m); println(shell.sock))

handlers(shell::Electron) = shell.handlers

function initcbs(shell)
  enable_callbacks!(shell)
  @schedule begin
    while active(shell)
      @errs handle_message(shell, JSON.parse(shell.sock))
    end
  end
end

# utils

import Base: quit

export active

active(shell::Electron) = process_running(shell.proc)

quit(shell::Electron) = close(shell.sock)

# Default process

function shell(; debug = false)
  global _shell
  _shell ≠ nothing && active(_shell) && return _shell
  _shell = init(debug = debug)
end
