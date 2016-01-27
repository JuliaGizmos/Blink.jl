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
jsexpr(io, x::Symbol) = (x==:nothing ? print(io, "null") : print(io, x))
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

function block_expr(io, args)
  print(io, "{")
  jsexpr_joined(io, rmlines(args), "; ")
  print(io, "}")
end

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

function if_expr(io, xs)
    if length(xs) >= 2  # we have an if
        print(io, "if (")
        jsexpr(io, xs[1])
        print(io, ") ")
        jsexpr(io, xs[2])
    end

    if length(xs) == 3  # Also have an else
        print(io, "else")
        jsexpr(io, xs[3])
    end
end

function jsexpr(io, x::Expr)
  isexpr(x, :block) && return block_expr(io, x.args)
  @match x begin
    d(xs__) => dict_expr(io, xs)
    f_(xs__) => call_expr(io, f, xs...)
    (a_ -> b_) => func_expr(io, a, b)
    a_.b_ | a_.(b_) => jsexpr_joined(io, [a, b], ".")
    (a_ = b_) => jsexpr_joined(io, [a, b], "=")
    $(Expr(:comparison, :_, :(==), :_)) => jsexpr_joined(io, [x.args[1], x.args[3]], "==")
    $(Expr(:if, :__)) => if_expr(io, x.args)
    a_[i__] => ref_expr(io, a, i...)
    (@m_ xs__) => jsexpr(io, macroexpand(Blink, x))
    (c_ ? t_ : f_) => (jsexpr(io, c); print(io, "?"); jsexpr(io, t); print(io, ":"); jsexpr(io, f))
    (return a_) => (print(io, "return "); jsexpr(io, a))
    $(Expr(:function, :__)) => func_expr(io, x.args...)
    $(Expr(:new, :_)) => (print(io, "new "); jsexpr(io, x.args[1]))
    $(Expr(:var, :_)) => (print(io, "var "); jsexpr(io, x.args[1]))
    _ => error("JSExpr: Unsupported `$(x.head)` expression, $x")
  end
end

macro new(x) esc(Expr(:new, x)) end
macro var(x) esc(Expr(:var, x)) end
