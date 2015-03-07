using Requires, Lazy

export render, setdisplay, unsetdisplay, getdisplay, current_input, Media, @media, media

# Some type system utils

distance(S, T) =
  !(S <: T) ? Inf :
  S == T ? 0. :
  1 + distance(super(S), T)

nearest(T, U, V) =
  distance(T, U) < distance(T, V) ? U : V

nearest(T, Ts) =
  reduce((U, V) -> nearest(T, U, V), Ts)

function compare2desc(ex)
  (isexpr(ex, :comparison) && ex.args[2] == :(<:)) || return ex
  return Expr(:(<:), ex.args[1], ex.args[3])
end

"""
Similar to `abstract`:

    @media Foo

defines Foo, as well as FooT, the type representing Foo
and its descendants (which is useful for dispatch).

    @media Bar <: Foo
    Bar::FooT
"""
macro media (def)
  T = namify(def)
  def = compare2desc(def)
  quote
    abstract $def
    typealias $(symbol(string(T, "T"))){T<:$T} Type{T}
    nothing
  end |> esc
end

# The media heirarchy defines an extensible set of possible
# output types. Displayable types are associated with a media
# type as a trait.

@media Graphical
@media Plot <: Graphical
@media Image <: Graphical

@media Textual
@media Numeric <: Textual
@media RichText <: Textual

@media Tabular
@media Matrix <: Tabular
@media List <: Tabular
@media Dataset <: Tabular

"""
`media(T)` gives the media type of the type `T`.
The default is `Textual`.

    media(Gadfly.Plot) == Media.Plot
"""
media(x) = media(typeof(x))

media(T, M) =
  @eval media{T<:$T}(::Type{T}) = $M

media(Any, Media.Textual)

media(AbstractMatrix, Media.Matrix)
media(AbstractVector, Media.List)

@require Gadfly media(Gadfly.Plot, Media.Plot)
@require Images media(Images.Image, Media.Image)
@require DataFrames media(DataFrames.DataFrame, Media.Dataset)

# A "pool" simply associates types with output devices. Obviously
# the idea is to use media types for genericity, but object types
# (e.g. `Float64`, `AbstractMatrix`) can also be used (which will
# override the media trait of the relevant objects).

const _pool = @d()

pool() = _pool

setdisplay(T, output) =
  pool()[T] = output

unsetdisplay(T) =
  haskey(pool(), T) && delete!(pool(), T)

function getdisplay(T, pool)
  K = nearest(T, [Any, keys(pool)...])
  K == Any && (K = nearest(media(T), keys(pool)))
  return pool[K]
end

# There should be a pool associated with each input device. Normally,
# it should take into account the global pool. The device should
# also override `setdisplay(input, T, output)`

# This design allows e.g. terminal and IJulia displays to be linked
# to their respective inputs, so that both can be used simultaneously
# with the same kernel. At the same time you can link a global display
# to both (e.g. a popup window for plots).

pool(input) = pool()

setdisplay(T, output) =
  pool()[T] = output

# In order to actually display things, we need to know what the current
# input device is. This is stored as a dynamically-bound global variable,
# with the intention that an input device will rebind the current input
# to itself whenever it evaluates code.

# This will also be useful for device-specific functionality like reading
# input and producing warnings.

@dynamic input::Any = nothing

current_input() = input[]

# e.g.

# @dynamic let Media.input = REPL
#   eval(:(render(x)))
# end

# `render` is a stand-in for `display` here.
# Displays should override `render` to display the given object appropriately.
# `options` can be used to override implementation details like mime type.

render(x; options = Dict()) =
  render(getdisplay(typeof(x), pool(current_input())), x; options = options)
