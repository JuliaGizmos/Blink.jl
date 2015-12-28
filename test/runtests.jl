using Blink
using Base.Test

# open window and wait for it to initialize
w = Window(Blink.@d(:show => false)); sleep(5.0)

# make sure the window is really active
@test_approx_eq @js(w, Math.log(10)) log(10)
