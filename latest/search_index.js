var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Blink.jl Documentation",
    "title": "Blink.jl Documentation",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#Blink.jl-Documentation-1",
    "page": "Blink.jl Documentation",
    "title": "Blink.jl Documentation",
    "category": "section",
    "text": ""
},

{
    "location": "index.html#Overview-1",
    "page": "Blink.jl Documentation",
    "title": "Overview",
    "category": "section",
    "text": "Blink.jl is the Julia wrapper around Electron. It  can serve HTML content in a local window, and allows for communication between Julia and the web page. In this way, therefore, Blink can be used as a GUI toolkit for building HTML-based applications for the desktop."
},

{
    "location": "index.html#Installation-1",
    "page": "Blink.jl Documentation",
    "title": "Installation",
    "category": "section",
    "text": "To install Blink, run:julia> Pkg.add(\"Blink\")\njulia> Blink.AtomShell.install()This will install the package, and its dependencies: namely, Electron."
},

{
    "location": "index.html#Documentation-Outline-1",
    "page": "Blink.jl Documentation",
    "title": "Documentation Outline",
    "category": "section",
    "text": ""
},

{
    "location": "guide.html#",
    "page": "Usage Guide",
    "title": "Usage Guide",
    "category": "page",
    "text": ""
},

{
    "location": "guide.html#Usage-Guide-1",
    "page": "Usage Guide",
    "title": "Usage Guide",
    "category": "section",
    "text": "Using Blink to build a local web app has two basic steps:Create a window and load all your HTML and JS.\nHandle interaction between julia and your window."
},

{
    "location": "guide.html#.-Setting-up-a-new-Blink-Window-1",
    "page": "Usage Guide",
    "title": "1. Setting up a new Blink Window",
    "category": "section",
    "text": "Create a new window via Window, and load some html via body!.julia> using Blink\n\njulia> w = Window(async=false) # Open a new window\nBlink.AtomShell.Window(...)\n\njulia> body!(w, \"Hello World\", async=false) # Set the body contentThe main functions for setting content on a window are content!(w, querySelector, html) and body!(w, html). body! is just shorthand for content!(w, \"body\", html).You can also load an external url via loadurl, which will replace the current content of the window:loadurl(w, \"http://julialang.org\") # Load a web pageNote the use of async=false in the examples above. By default, these functions return immediately, but setting async=false will block until the function has completed. This is important if you are executing multiple statements in a row that depend on the previous statement having completed."
},

{
    "location": "guide.html#Loading-stadalone-HTML,-CSS-and-JS-files-1",
    "page": "Usage Guide",
    "title": "Loading stadalone HTML, CSS & JS files",
    "category": "section",
    "text": "You can load complete standalone files via the load! function. Blink will handle the file correctly based on its file type suffix:load!(w, \"ui/app.css\")\nload!(w, \"ui/frameworks/jquery-3.3.1.js\")You can also call the corresponding importhtml!, loadcss!, and loadjs! directly."
},

{
    "location": "guide.html#.-Setting-up-interaction-between-Julia-and-JS-1",
    "page": "Usage Guide",
    "title": "2. Setting up interaction between Julia and JS",
    "category": "section",
    "text": "using Blink\nw = Window(Dict(:show=>false), async=false)This topic is covered in more detail in the Communication page.Just as you can directly write to the DOM via content!, you can directly execute javscript via the @js macro.@js w Math.log(10)To invoke julia code from javascript, you can pass a \"message\" to julia:# Set up julia to handle the \"press\" message:\nhandle(w, \"press\") do args\n  @show args\nend\n# Invoke the \"press\" message from javascript whenever this button is pressed:\nbody!(w, \"\"\"<button onclick=\'Blink.msg(\"press\", \"HELLO\")\'>go</button>\"\"\");"
},

{
    "location": "communication.html#",
    "page": "Communication",
    "title": "Communication",
    "category": "page",
    "text": ""
},

{
    "location": "communication.html#Communication-1",
    "page": "Communication",
    "title": "Communication between Julia and Javascript",
    "category": "section",
    "text": "After creating a Window and loading HTML and JS, you may want to interact with julia code (e.g. by clicking a button in HTML, or displaying a plot from julia).This section covers this two-way communication."
},

{
    "location": "communication.html#Julia-to-Javascript-1",
    "page": "Communication",
    "title": "Julia to Javascript",
    "category": "section",
    "text": "using Blink\nwin = Window(Dict(:show=>false), async=false)The easiest way to communicate to javascript from julia is with the @js and @js_ macros. These macros allow you to execute arbitrary javascript code in a given Window.@js win x = 5;\n@js win xThe @js_ macro executes its code asynchronously, but doesn\'t return its result:@time @js win begin   # Blocks until finished; `i` is returned\n  for i in 0:1000000 end  # waste time\n  i  # return i\nend\n\n@time @js_ win begin   # Returns immediately, but `i` is not returned.\n  for i in 0:1000000 end  # waste time\n  i  # This is ignored\nendIf your javascript expression is complex, or you want to copy-paste existing javascript, it can be easier to represent it as a pure javascript string. For that, you can call the js function with a JSString:body!(win, \"\"\"<div id=\"box\" style=\"color:red;\"></div>\"\"\", async=false);\ndiv_id = \"box\";\njs(win, Blink.JSString(\"\"\"document.getElementById(\"$div_id\").style.color\"\"\"))Note that the code passed to these macros runs in its own scope, so any javascript variables you create with var (or the @var equivalent for @js) will be inaccessible after returning:@js win (@var x_var = 5; x_var)  # x_var is only accessible within this scope.\n@js win x_var"
},

{
    "location": "communication.html#Javascript-to-Julia-1",
    "page": "Communication",
    "title": "Javascript to Julia",
    "category": "section",
    "text": "Communication from javascript to julia currently works via a message passing interface.To invoke julia code from javascript, you specify a julia callback via handle:julia> handle(w, \"press\") do args\n         @show args\n       endThis callback can then be triggered from javscript via Blink.msg():using Blink\nw = Window(Dict(:show=>false), async=false)\nhandle(w, \"press\") do args\n  @show args\nend@js w Blink.msg(\"press\", \"Hello from JS\");Note that the javascript function Blink.msg takes exactly 1 argument.  To pass more or fewer arguments, pass your arguments as an array:handle(w, \"event\") do count, values, message\n  # ...\nend\n@js w Blink.msg(\"event\", [1, [\'a\',\'b\'], \"Hi\"]);Finally, here is an example that uses a button to call back to julia:using Blink\nw = Window(Dict(:show=>false), async=false)handle(w, \"press\") do arg\n  println(arg)\nend\nbody!(w, \"\"\"<button onclick=\'Blink.msg(\"press\", \"HELLO\")\'>go</button>\"\"\", async=false);Now, clicking the button will print HELLO to julia\'s STDOUT."
},

{
    "location": "communication.html#Back-and-forth-1",
    "page": "Communication",
    "title": "Back-and-forth",
    "category": "section",
    "text": "Note that you cannot make a synchronous call to javascript from within a julia callback, or you\'ll cause julia to hang:BAD:julia> @js w x = 5\n\njulia> handle(w, \"press\") do args...\n         # Increment x and get its new value\n         x = @js w (x += 1; x)  # ERROR: Cannot make synchronous calls within a callback.\n         println(\"New value: $x\")\n       end\n#9 (generic function with 1 method)\n\njulia> @js w Blink.msg(\"press\", [])\n\n# JULIA HANGS UNTIL CTRL-C, WHICH KILLS YOUR BLINK WINDOW.GOOD: Instead, if you need to access the value of x, you should simply provide it when invoking the press handler:@js w x = 5\n\nhandle(w, \"press\") do args...\n  x = args[1]\n  # Increment x\n  @js_ w (x = $x + 1)  # Note the _asynchronous_ call.\n  println(\"New value: $x\")\nend\n\n@js w Blink.msg(\"press\", x)\n# JULIA HANGS UNTIL CTRL-C, WHICH KILLS YOUR BLINK WINDOW."
},

{
    "location": "communication.html#Tasks-1",
    "page": "Communication",
    "title": "Tasks",
    "category": "section",
    "text": "The julia webserver is implemented via Julia Tasks. This means that julia code invoked from javascript will run sort of in parallel to your main julia code.In particular:Tasks are coroutines, not threads, so they aren\'t truly running in parallel.\nInstead, execution can switch between your code and the coroutine\'s code whenever a piece of computation is interruptible.So, if your Blink callback handler performs uninterruptible work, it will fully occupy your CPU, preventing any other computation from occuring, and can potentially hang your computation."
},

{
    "location": "communication.html#Examples:-1",
    "page": "Communication",
    "title": "Examples:",
    "category": "section",
    "text": "BAD: If your callback runs a long loop, it won\'t be uninterruptible while it\'s running:julia> handle(w, \"press\") do args...\n         println(\"Start\")\n         while true end  # infinite loop\n         println(\"End\")\n       end\n#40 (generic function with 1 method)\n\njulia> body!(w, \"\"\"<button onclick=\'Blink.msg(\"press\", 1)\'>go</button>\"\"\", async=false);\n\njulia> # CLICK THE go BUTTON, AND YOUR PROCESS WILL FREEZE\nStartBAD: The same is true if your main julia computation is hogging the CPU, then your callback can\'t run:julia> handle(w, \"press\") do args...\n         println(\"Start\")\n         sleep(5) # This will happily yield to any other computation.\n         println(\"End\")\n       end\n#41 (generic function with 1 method)\n\njulia> body!(w, \"\"\"<button onclick=\'Blink.msg(\"press\", 1)\'>go</button>\"\"\", async=false);\n\njulia> while true end  # Infinite loop\n\n# NOW, CLICK THE go BUTTON, AND NOTHING HAPPENS, SINCE THE CPU IS BEING HOGGED!GOOD: So to allow for happy communication, all your computations should be interruptible, which you can achieve with calls such as yield, or sleep:julia> handle(w, \"press\") do args...\n         println(\"Start\")\n         sleep(5) # This will happily yield to any other computation.\n         println(\"End\")\n       end\n#39 (generic function with 1 method)\n\njulia> body!(w, \"\"\"<button onclick=\'Blink.msg(\"press\", 1)\'>go</button>\"\"\", async=false);\n\njulia> while true  # Still an infinite loop, but a _fair_ one.\n         yield()  # This will yield to any other computation, allowing the callback to run.\n       end\n\n# NOW, CLICKING THE go BUTTON WILL WORK CORRECTLY ✅\nStart\nEnd"
},

{
    "location": "api.html#",
    "page": "API",
    "title": "API",
    "category": "page",
    "text": ""
},

{
    "location": "api.html#API-1",
    "page": "API",
    "title": "API",
    "category": "section",
    "text": ""
},

{
    "location": "api.html#Blink.AtomShell.Window",
    "page": "API",
    "title": "Blink.AtomShell.Window",
    "category": "type",
    "text": "Window()\nWindow(electron_options::Dict; async=true)\n\nCreate and open a new Window through Electron.\n\nIf async==false, this function blocks until the Window is fully initialized and ready for you to communicate with it via javascript or the Blink API.\n\nThe electron_options dict is used to initialize the Electron window. See here for the full set of Electron options: https://electronjs.org/docs/api/browser-window#new-browserwindowoptions\n\n\n\n\n\n"
},

{
    "location": "api.html#Blink.AtomShell.title",
    "page": "API",
    "title": "Blink.AtomShell.title",
    "category": "function",
    "text": "title(win::Window, title)\n\nSet win\'s title to title.\n\n\n\n\n\ntitle(win::Window)\n\nGet the window\'s title.\n\n\n\n\n\n"
},

{
    "location": "api.html#Blink.AtomShell.progress",
    "page": "API",
    "title": "Blink.AtomShell.progress",
    "category": "function",
    "text": "progress(win::Window, p=-1)\n\nSets progress value in progress bar. Valid range is [0, 1.0]. Remove progress bar when progress < 0; Change to indeterminate mode when progress > 1.\n\nhttps://github.com/electron/electron/blob/master/docs/api/browser-window.md#winsetprogressbarprogress-options\n\n\n\n\n\n"
},

{
    "location": "api.html#Blink.AtomShell.flashframe",
    "page": "API",
    "title": "Blink.AtomShell.flashframe",
    "category": "function",
    "text": "flashframe(win::Window, on=true)\n\nStart or stop \"flashing\" the window to get the user\'s attention.\n\nIn Windows, flashes the window frame. In MacOS, bounces the app in the Dock. https://github.com/electron/electron/blob/master/docs/api/browser-window.md#winflashframeflag\n\n\n\n\n\n"
},

{
    "location": "api.html#Window-1",
    "page": "API",
    "title": "Window",
    "category": "section",
    "text": "Windowtitle\nprogress\nflashframe"
},

{
    "location": "api.html#Blink.AtomShell.opentools",
    "page": "API",
    "title": "Blink.AtomShell.opentools",
    "category": "function",
    "text": "opentools(win::Window)\n\nOpen the Chrome Developer Tools on win.\n\nSee also: closetools, tools\n\n\n\n\n\n"
},

{
    "location": "api.html#Blink.AtomShell.closetools",
    "page": "API",
    "title": "Blink.AtomShell.closetools",
    "category": "function",
    "text": "closetools(win::Window)\n\nClose the Chrome Developer Tools on win if open.\n\nSee also: opentools, tools\n\n\n\n\n\n"
},

{
    "location": "api.html#Blink.AtomShell.tools",
    "page": "API",
    "title": "Blink.AtomShell.tools",
    "category": "function",
    "text": "tools(win::Window)\n\nToggle the Chrome Developer Tools on win.\n\nSee also: opentools, closetools\n\n\n\n\n\n"
},

{
    "location": "api.html#Misc-1",
    "page": "API",
    "title": "Misc",
    "category": "section",
    "text": "opentools\nclosetools\ntools"
},

{
    "location": "api.html#JSExpr.@js",
    "page": "API",
    "title": "JSExpr.@js",
    "category": "macro",
    "text": "@js win expr\n\nExecute expr, converted to javascript, inside win, and return the result.\n\nexpr will be parsed as julia code, and then converted directly to the equivalent javascript. Language keywords that don\'t exist in julia can be represented with their macro equivalents, @var, @new, etc.\n\nSee also: @js_, the asynchronous version.\n\nExamples\n\njulia> @js win x = 5\n5\njulia> @js_ win for i in 1:x console.log(i) end\n\n\n\n\n\n"
},

{
    "location": "api.html#Blink.@js_",
    "page": "API",
    "title": "Blink.@js_",
    "category": "macro",
    "text": "@js_ win expr\n\nExecute expr, converted to javascript, asynchronously inside win, and return immediately.\n\nexpr will be parsed as julia code, and then converted directly to the equivalent javascript. Language keywords that don\'t exist in julia can be represented with their macro equivalents, @var, @new, etc.\n\nSee also: @js, the synchronous version that returns its result.\n\nExamples\n\njulia> @js win x = 5\n5\njulia> @js_ win for i in 1:x console.log(i) end\n\n\n\n\n\n"
},

{
    "location": "api.html#Blink.js",
    "page": "API",
    "title": "Blink.js",
    "category": "function",
    "text": "js(win, expr::JSString; callback=false)\n\nExecute the javscript in expr, inside win.\n\nIf callback==true, returns the result of evaluating expr.\n\n\n\n\n\n"
},

{
    "location": "api.html#WebIO.JSString",
    "page": "API",
    "title": "WebIO.JSString",
    "category": "type",
    "text": "JSString(str)\n\nA wrapper around a string indicating the string contains javascript code.\n\n\n\n\n\n"
},

{
    "location": "api.html#RPC-1",
    "page": "API",
    "title": "RPC",
    "category": "section",
    "text": "@js\n@js_\njs\nBlink.JSString"
},

]}
