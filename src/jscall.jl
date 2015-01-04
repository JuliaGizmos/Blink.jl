export js, js_, @js, @js_, @var, @new

const callbacks = Dict{Int,Condition}()

shellinit() do shell
  @schedule begin
    while active(shell)
      data = JSON.parse(shell.sock)
      if haskey(data, "callback") && haskey(callbacks, data["callback"])
        notify(callbacks[data["callback"]], data["result"])
        delete!(callbacks, data["callback"])
      end
    end
  end
end

const counter = [0]
cb() = counter[1] += 1

function js(shell::AtomShell, js; callback = true)
  cmd = @d(:command => :eval,
           :code => jsexpr(js).s)
  if callback
    id, cond = cb(), Condition()
    cmd[:callback] = id
    callbacks[id] = cond
  end
  JSON.print(shell.sock, cmd)
  println(shell.sock)
  if callback
    return wait(cond)
  end
end

js_(args...) = js(args..., callback = false)

macro js_(shell, ex)
  :(js_($(esc(shell)), $(Expr(:quote, ex))))
end

macro js(shell, ex)
  :(js($(esc(shell)), $(Expr(:quote, ex))))
end
