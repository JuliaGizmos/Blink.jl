# Blink.jl Documentation

## Overview

Blink.jl provides a API for communicating with web pages from Julia. Pages may
be served over the internet and controlled from the browser, or served locally
via an [Electron](https://electronjs.org/) window. Blink can therefore be used
as a GUI toolkit – DevTools.jl for an example use.

## Installation
To install Blink, run:

```julia-repl
julia> Pkg.add("Blink")
julia> Blink.AtomShell.install()
```

This will install the package, and its dependencies: namely, `Electron`.

## Documentation Outline

```@contents
```
