using Lazy, JSON

hascommand(c) =
  try readall(`which $c`); true catch e false end

spawn_rdr(cmd) = spawn(cmd, Base.spawn_opts_inherit()...)

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

import Base: Process, TcpSocket

export Shell

type Shell
  proc::Process
  sock::TcpSocket
  handlers::Dict{ASCIIString, Any}
end

Shell(proc, sock) = Shell(proc, sock, Dict())

@osx_only     const atom = Pkg.dir("Blink", "deps/Julia.app/Contents/MacOS/Julia")
@linux_only   const atom = Pkg.dir("Blink", "deps/atom/atom")
@windows_only const atom = Pkg.dir("Blink", "deps", "atom", "atom.exe")
const mainjs = Pkg.dir("Blink", "src", "AtomShell", "main.js")

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
  p, dp = port(), port()
  debug && inspector(dp)
  dbg = debug ? "--debug=$dp" : []
  proc = (debug ? spawn_rdr : spawn)(`$atom $dbg $mainjs port $p`)
  conn = try_connect(ip"127.0.0.1", p)
  shell = Shell(proc, conn)
  initcbs(shell)
  return shell
end

# JS Communication

import ..Blink: msg, enable_callbacks!, handlers, handle_message, active

msg(shell::Shell, m) = (JSON.print(shell.sock, m); println(shell.sock))

handlers(shell::Shell) = shell.handlers

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

active(shell::Shell) = process_running(shell.proc)

quit(shell::Shell) = close(shell.sock)

# Default process

_shell = nothing

function shell(; debug = false)
  global _shell
  _shell ≠ nothing && active(_shell) && return _shell
  _shell = init(debug = debug)
end
