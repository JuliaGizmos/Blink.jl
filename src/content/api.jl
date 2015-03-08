export body, content!

content!(o, sel, html::String) =
  @js_ o document.querySelector($sel).innerHTML = $html

body(w, html) = content!(w, "body", html)
