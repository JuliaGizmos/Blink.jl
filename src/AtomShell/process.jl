using Lazy, JSON, MacroTools

hascommand(c) =
  try read(`which $c`, String); true catch e false end

run_rdr(cmd; kw...) = run(cmd, Base.spawn_opts_inherit()...; kw...)

"""
  resolve_blink_asset(path...)

Find a file, expressed as a relative path from the Blink package
folder. Example:

  resolve_blink_asset("src", "Blink.jl") -> /home/<user>/.julia/v0.6/Blink/src/Blink.jl
"""
resolve_blink_asset(path...) = abspath(joinpath(@__DIR__, "..", "..", path...))

@deprecate resolve(pkg, path...) resolve_blink_asset(path...)

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
  run(`open http://localhost:8080/debug'?'port=$port`)
end

# atom-shell

import Base: Process

export Electron

mutable struct Electron <: Shell
  proc::Process
  sock::TCPSocket
  handlers::Dict{String, Any}
end

Electron(proc, sock) = Electron(proc, sock, Dict())

@static if Sys.isapple()
  const _electron = resolve_blink_asset("deps/Julia.app/Contents/MacOS/Julia")
elseif Sys.islinux()
  const _electron = resolve_blink_asset("deps/atom/electron")
elseif Sys.iswindows()
  const _electron = resolve_blink_asset("deps", "atom", "electron.exe")
end
const mainjs = resolve_blink_asset("src", "AtomShell", "main.js")

function electron()
  path = get(ENV, "ELECTRON_PATH", _electron)
  isfile(path) || error("Cannot find Electron. Try `Blink.AtomShell.install()`.")
  return path
end

port() = rand(2_000:10_000)

function try_connect(args...; interval = 0.01, attempts = 300)
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
  proc = (debug ? run_rdr : run)(`$(electron()) $dbg $mainjs port $p`; wait=false)
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
  @async begin
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
