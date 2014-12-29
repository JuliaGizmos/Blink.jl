using JSON

jsexpr(io, x) = JSON.print(io, x)

jsexpr(io, xs...) = for x in xs jsexpr(io, x) end

jsexpr(xs...) = sprint(jsexpr, xs...)

# Expressions

jsexpr(io, x::Symbol) = print(io, x)
jsexpr(io, x::QuoteNode) = jsexpr(io, x.value)

function jsexpr_joined(io, xs, delim=",")
  isempty(xs) && return
  for i = 1:length(xs)-1
    jsexpr(io, xs[i])
    print(io, delim)
  end
  jsexpr(io, xs[end])
end

function call_expr(io, f, args...)
  jsexpr(io, f)
  print(io, "(")
  jsexpr_joined(io, args)
  print(io, ")")
end

jsexpr(io, x::Expr) =
  @switch isexpr(x, _),
    :call -> call_expr(io, x.args...),
    :. -> (jsexpr(io, x.args[1]); print(io, "."); jsexpr(io, x.args[2])),
    error("Unsupported JS expression `$(x.head)`")
