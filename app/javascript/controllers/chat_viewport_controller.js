import { Controller } from "@hotwired/stimulus"

// On phones the virtual keyboard shrinks the visible area but not 100vh, so the
// browser scrolls the whole page to reveal the focused field and the greeting
// ends up above the screen. Here the chat section is sized to the visual
// viewport (the space above the keyboard) and the page is kept at the top.
// Desktop keeps the plain CSS height.
export default class extends Controller {
  connect() {
    this.viewport = window.visualViewport
    if (!this.viewport) return

    this.mobile = window.matchMedia("(max-width: 639px)")
    this.fit = this.fit.bind(this)
    this.viewport.addEventListener("resize", this.fit)
    this.mobile.addEventListener("change", this.fit)
    this.fit()
  }

  disconnect() {
    this.viewport?.removeEventListener("resize", this.fit)
    this.mobile?.removeEventListener("change", this.fit)
    this.element.style.height = ""
  }

  fit() {
    if (!this.mobile.matches) {
      this.element.style.height = ""
      return
    }

    const top = this.element.getBoundingClientRect().top + window.scrollY
    this.element.style.height = `${this.viewport.height - top}px`
    window.scrollTo(0, 0)
  }
}
