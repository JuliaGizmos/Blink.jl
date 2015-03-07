export body

body(o, html::String) =
  @js_ o document.body.innerHTML = $html
