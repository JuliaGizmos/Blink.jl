using Lazy, JSON, MacroTools
export JSString

jsexpr(io, x) = JSON.print(io, x)

type JSString
  s::UTF8String
end

jsexpr(x) = JSString(sprint(jsexpr, x))

jsstring(x) = jsexpr(x).s

macro js_str(s)
  :(JSString($(esc(s))))
end

# Expressions

jsexpr(io, x::JSString) = print(io, x.s)
jsexpr(io, x::Symbol) = print(io, x)
jsexpr(io, x::QuoteNode) = jsexpr(io, x.value)
jsexpr(io, x::LineNumberNode) = nothing

function jsexpr_joined(io::IO, xs, delim=",")
  isempty(xs) && return
  for i = 1:length(xs)-1
    jsexpr(io, xs[i])
    print(io, delim)
  end
  jsexpr(io, xs[end])
end

jsexpr_joined(xs, delim=",") = sprint(jsexpr_joined, xs, delim)

function call_expr(io, f, args...)
  f in [:(=), :+, :-, :*, :/, :%] &&
    return print(io, "(", jsexpr_joined(args, string(f)), ")")
  jsexpr(io, f)
  print(io, "(")
  jsexpr_joined(io, args)
  print(io, ")")
end

function ref_expr(io, x, args...)
  jsexpr(io, x)
  print(io, "[")
  jsexpr_joined(io, args)
  print(io, "]")
end

function func_expr(io, args, body)
  named = isexpr(args, :call)
  named || print(io, "(")
  print(io, "function ")
  if named
    print(io, args.args[1])
    args = args.args[2]
  end
  print(io, "(")
  isexpr(args, Symbol) ? print(io, args) : print_joined(io, args.args, ",")
  print(io, ")")
  print(io, "{")
  jsexpr(io, body)
  print(io, "}")
  named || print(io, ")")
end

function dict_expr(io, xs)
  print(io, "{")
  xs = ["$(x.args[1]::AbstractString):"*jsexpr(x.args[2]).s for x in xs]
  print_joined(io, xs, ",")
  print(io, "}")
end

jsexpr(io, x::Expr) =
  @switch isexpr(x, _),
    :call -> call_expr(io, x.args...),
    :-> -> func_expr(io, x.args...),
    :function -> func_expr(io, x.args...),
    :. -> jsexpr_joined(io, x.args, "."),
    :(=) -> jsexpr_joined(io, x.args, "="),
    :block -> jsexpr_joined(io, x.args, ";"),
    :new -> (print(io, "new "); jsexpr(io, x.args[1])),
    :var -> (print(io, "var "); jsexpr(io, x.args[1])),
    :ref -> ref_expr(io, x.args...),
    :macrocall -> jsexpr(io, macroexpand(Blink, x)),
    :line -> nothing,
    :return -> (print(io, "return "); jsexpr(io, x.args[1])),
    :dict -> dict_expr(io, x.args),
    error("JSExpr: Unsupported `$(x.head)` expression, $x")

macro new(x) esc(Expr(:new, x)) end
macro var(x) esc(Expr(:var, x)) end
