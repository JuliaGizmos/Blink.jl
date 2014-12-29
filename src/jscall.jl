export js, @js

function js(shell::AtomShell, js::String)
  JSON.print(shell.sock, @d(:command => :eval,
                            :code => js))
  println(shell.sock)
end

js(shell::AtomShell, ex) = js(shell, jsexpr(ex))

macro js(shell, ex)
  :(js($(esc(shell)), $(Expr(:quote, ex))))
end
