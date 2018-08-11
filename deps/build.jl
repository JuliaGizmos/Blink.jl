module BuildBlink
# put into module b/c some globals are defined in install.jl

include(joinpath(@__DIR__, "../src/AtomShell/install.jl"))

function get_installed_version()
    _path = Sys.isapple() ?
        joinpath(folder(), "version") :
        joinpath(folder(), "atom", "version")
    strip(readstring(_path), 'v')
end

if isinstalled() && !(version == get_installed_version())
    install()
end

end
