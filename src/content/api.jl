export body!, content!

content!(o, sel, html::String) =
  @js_ o document.querySelector($sel).innerHTML = $html

content!(o, sel, html) =
  content!(o, sel, stringmime(MIME"text/html"(), html))

body!(w, html) = content!(w, "body", html)
