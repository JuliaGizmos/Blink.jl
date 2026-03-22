import JSExpr: @js, @js_str, JSString, jsstring, @var, @new, deparse, crawl, JSNode, JSAST, JSTerminal, interpolate

export js, @js, @js_, @var, @new

# include("jsexprs.jl")

include("callbacks.jl")

mutable struct JSError <: Exception
    name::String
    msg::String
end

Base.showerror(io::IO, e::JSError) =
    print(io, "Javascript error\t$(e.name): $(e.msg)")

# RPC API

export js, js_, @js, @js_, @var, @new

"""
    js(win, expr::JSString; callback=false)

Execute the javscript in `expr`, inside `win`.

If `callback==true`, returns the result of evaluating `expr`.
"""
function js end

"""
    JSString(str)

A wrapper around a string indicating the string contains javascript code.
"""
function JSString end

msg(o, m) = error("$(typeof(o)) object doesn't support JS messages")

function js(o, js::JSString; callback = true)
  cmd = Dict(:type => :eval,
           :code => js.s)
  if callback
    id, cond = callback!()
    cmd[:callback] = id
  end
  msg(o, cmd)

  if callback
            val = wait_callback(cond)
      if isa(val, AbstractDict) && get(val, "type", "") == "error"
          err = JSError(get(val, "name", "unknown"), get(val, "message", "blank"))
          throw(err)
      end
      return val
  else
      return o
  end
end

function js(o, j; callback=true)
        x = JSString(string(jsstring(j)))
    js(o, x; callback=callback)
end

function _materialize_jsstring_arg(arg)
    if arg isa QuoteNode
        return arg.value
    elseif arg isa Expr && arg.head == :call && arg.args[1] == :jsstring
        parts = map(_materialize_jsstring_arg, arg.args[2:end])
        return jsstring(parts...)
    else
        return arg
    end
end

function _materialize_crawled_jsnode(ex)
    if ex === nothing
        return nothing
    elseif ex isa JSNode
        return ex
    elseif !(ex isa Expr) || ex.head != :call
        return JSTerminal(ex)
    end

    f = ex.args[1]
    if f === :JSAST
        head = ex.args[2] isa QuoteNode ? ex.args[2].value : ex.args[2]
        args = map(_materialize_crawled_jsnode, ex.args[3:end])
        return JSAST(head, args...)
    elseif f === :JSTerminal
        arg = _materialize_jsstring_arg(ex.args[2])
        return JSTerminal(arg)
    else
        throw(ArgumentError("Unsupported crawled JSExpr node: $ex"))
    end
end

function js(o, j::Expr; callback=true)
    ast_expr = crawl(j)
    jsnode = _materialize_crawled_jsnode(ast_expr)
    x = deparse(jsnode)
    js(o, x; callback=callback)
end

"""
    @js win expr

Execute `expr`, converted to javascript, inside `win`, and return the result.

`expr` will be parsed as julia code, and then converted directly to the
equivalent javascript. Language keywords that don't exist in julia can be
represented with their macro equivalents, `@var`, `@new`, etc.

See also: `@js_`, the asynchronous version.

# Examples
```julia-repl
julia> @js win x = 5
5
julia> @js_ win for i in 1:x console.log(i) end
```
"""
macro js(o, ex)
    ex = Expr(:call, :deparse, crawl(ex))
    :(js($(esc(o)), $ex))
end

"""
    @js_ win expr

Execute `expr`, converted to javascript, asynchronously inside `win`, and return
immediately.

`expr` will be parsed as julia code, and then converted directly to the
equivalent javascript. Language keywords that don't exist in julia can be
represented with their macro equivalents, `@var`, `@new`, etc.

See also: `@js`, the synchronous version that returns its result.

# Examples
```julia-repl
julia> @js win x = 5
5
julia> @js_ win for i in 1:x console.log(i) end
```
"""
macro js_(o, ex)
    ex = Expr(:call, :deparse, crawl(ex))
    :(js($(esc(o)), $ex, callback=false))
end
