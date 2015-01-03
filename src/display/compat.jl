# Compatibility with Julia's built-in display system

import Base.Multimedia: display

# Lives in the old system, forwarding to the new

type DisplayHook <: Display end

display(::DisplayHook, x) = render(x)

function hookless(f)
  popdisplay(DisplayHook())
  try
    return f()
  finally
    pushdisplay(DisplayHook())
  end
end

pushdisplay(DisplayHook())

# Lives in the new system

type NoDisplay end

function render(::NoDisplay, x; options = Dict())
  hookless() do
    haskey(options, :mime) ?
      display(options[:mime], x) :
      display(x)
  end
end

setdisplay(Any, NoDisplay())
