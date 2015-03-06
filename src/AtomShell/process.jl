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
  handlers
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

using Lazy, JSON
import ..Blink: js, jsexpr, JSString, callback!, handlers, handle_message

function js(shell::Shell, js::JSString; callback = true)
  cmd = @d(:command => :eval,
           :code => js.s)
  if callback
    id, cond = callback!()
    cmd[:callback] = id
  end
  JSON.print(shell.sock, cmd)
  println(shell.sock)
  return callback ? wait(cond) : shell
end

handlers(shell::Shell) = shell.handlers

function initcbs(shell)
  handle(shell, "callback") do data
    callback!(data["callback"], data["result"])
  end
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
