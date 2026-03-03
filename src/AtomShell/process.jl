using JSON, MacroTools, Pkg.Artifacts

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
  inspector_cmd = `http://localhost:8080/debug'?'port=$port`
  if Sys.isapple()
    return run(`open $inspector_cmd`)
  elseif Sys.islinux()
    return run(`xdg-open $inspector_cmd`)
  elseif Sys.iswindows()
    return run(`cmd /C start $inspector_cmd`)
  end
  error("Cannot open inspector (unknown operating system).")
end

# atom-shell

import Base: Process

export Electron
const _electron = artifact"electronjs_app"

mutable struct Electron <: Shell
  proc::Process
  sock::TCPSocket
  handlers::Dict{String, Any}
end

Electron(proc, sock) = Electron(proc, sock, Dict())

"""
resolve_electron_asset(path...)

Find a file, expressed as a relative path from the folder where
the Electron artifact was extracted. Example:

  resolve_electron_asset("julia.png") -> /home/<user>/.julia/artifacts/<git-tree-sha1>/julia.png
"""
resolve_electron_asset(path...) = abspath(joinpath(_electron, path...))

function electron()
  if Sys.isapple()
    return joinpath(_electron, "Julia.app", "Contents", "MacOS", "Julia")
  elseif Sys.iswindows()
    return joinpath(_electron, "electron.exe")
  else # assume unix layout
    return joinpath(_electron, "electron")
  end
end

port() = rand(2_000:10_000)

function try_connect(args...; interval = 0.01, attempts = 500)
  for i = 1:attempts
    try
      return connect(args...)
    catch e
      i == attempts && rethrow()
    end
    sleep(interval)
  end
end

const mainjs = resolve_blink_asset("src", "AtomShell", "main.js")

function init(; debug = false)
  electron() # Check path exists
  p, dp = port(), port()
  debug && inspector(dp)
  dbg = debug ? "--inspect=$dp" : []
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
    while active(shell) && !eof(shell.sock)  # check for eof to prevent errors during shutdown
      @errs handle_message(shell, JSON.parse(shell.sock))
    end
  end
end

# utils

export active

Base.close(shell::Electron) = close(shell.sock)
Base.isopen(shell::Electron) = process_running(shell.proc)

# TODO: Deprecate these functions in favor of methods above.
active(shell::Electron) = isopen(shell)
quit(shell::Electron) = close(shell)

# Keep track of the active electron process (see the `shell` function).
const _active_electron_process = Ref{Union{Electron, Nothing}}(nothing)

"""
    shell(; debug=false)

Get the currently active [`Electron`](@ref) shell instance (or activate one if
none exists yet).

NOTE: The `debug` keyword argument only takes effect if there is not an active
`Electron` instance. If there *is* an active instance, this function returns
that instance without regards to whether or not the `debug` flag matches.
"""
function shell(; debug=false)::Electron
    # TODO: It might make sense to track whether or not the shell was started
    # with the debug flag and issue a warning if the user requested debug and
    # the active shell is non-debug.
    proc = _active_electron_process[]
    if proc !== nothing && active(proc)
        return proc
    end

    proc = init(debug=debug)
    _active_electron_process[] = proc
    return proc
end
