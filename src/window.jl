export Window

type Window
  id::Int
  shell::AtomShell
end

function Window(a::AtomShell, opts::Associative)
  id = @js a createWindow($opts)
  return Window(id, a)
end
