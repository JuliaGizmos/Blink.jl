using JSON

jsexpr(io, x) = JSON.print(io, x)

jsexpr(x) = sprint(jsexpr, x)

# Expressions

jsexpr(io, x::Symbol) = print(io, x)
jsexpr(io, x::QuoteNode) = jsexpr(io, x.value)
jsexpr(io, x::LineNumberNode) = nothing

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
    :. -> jsexpr_joined(io, x.args, "."),
    :(=) -> jsexpr_joined(io, x.args, "="),
    :block -> jsexpr_joined(io, x.args, ";"),
    :new -> (print(io, "new "); jsexpr(io, x.args[1])),
    :var -> (print(io, "var "); jsexpr(io, x.args[1])),
    :macrocall -> jsexpr(io, macroexpand(x)),
    :line -> nothing,
    error("Unsupported JS expression `$(x.head)`")

macro new (x) esc(Expr(:new, x)) end
macro var (x) esc(Expr(:var, x)) end
