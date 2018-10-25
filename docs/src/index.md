# Blink.jl Documentation

## Overview

Blink.jl is the Julia wrapper around [Electron](https://electronjs.org/). It 
can serve HTML content in a local window, and allows for communication between
Julia and the web page. In this way, therefore, Blink can be used as a GUI
toolkit for building HTML-based applications for the desktop.

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
