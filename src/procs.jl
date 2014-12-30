# utils

hascommand(c) =
  try readall(`which $c`); true catch e false end

spawn_rdr(cmd) = spawn(cmd, Base.spawn_opts_inherit()...)

# node-inspector

_inspector = nothing

function inspector()
  hascommand("node-inspector") || error("You must have node-inspector installed to debug.")
  global _inspector
  _inspector != nothing && process_running(_inspector) && return _inspector
  _inspector = spawn_rdr(`node-inspector`)
end

function inspector(port)
  inspector()
  run(`open http://localhost:8080/debug?port=$port`)
end

# atom-shell

import Base: Process, TcpSocket

export AtomShell

type AtomShell
  proc::Process
  sock::TcpSocket
end

@osx_only const atom = Pkg.dir("Blink", "deps/Julia.app/Contents/MacOS/Julia")
const mainjs = Pkg.dir("Blink", "js", "main.js")

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

const hooks = Function[]
shellinit(f::Function) = push!(hooks, f)

function init(; debug = false)
  p, dp = port(), port()
  debug && inspector(dp)
  dbg = debug ? "--debug=$dp" : []
  proc = spawn_rdr(`$atom $dbg $mainjs port $p`)
  conn = try_connect(ip"127.0.0.1", p)
  shell = AtomShell(proc, conn)
  for f in hooks
    f(shell)
  end
  return shell
end
