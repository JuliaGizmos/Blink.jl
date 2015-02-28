@osx_only launch(x) = run(`open $x`)

@linux_only launch(x) = run(`xdg-open $x`)

@windows_only launch(x) = run(`cmd /C start $x`)
