import { Controller } from "@hotwired/stimulus"

// Enter sends the message (Shift+Enter still breaks the line). Desktop keyboards
// are caught on keydown; some Android keyboards don't report Enter there, so the
// line break they insert (beforeinput) is turned into a send as well.
// requestSubmit() with the "Enviar" button goes through Turbo like a click, so
// "Enviando…" and chat-typing still kick in, and the disabled button blocks
// double sends.
export default class extends Controller {
  static targets = ["input", "submit"]

  keydown(event) {
    this.shiftHeld = event.shiftKey
    if (event.key !== "Enter" || event.shiftKey || event.isComposing) return

    event.preventDefault()
    this.send()
  }

  beforeinput(event) {
    if (!["insertLineBreak", "insertParagraph"].includes(event.inputType) || this.shiftHeld) return

    event.preventDefault()
    this.send()
  }

  send() {
    if (this.inputTarget.value.trim() === "" || this.submitTarget.disabled) return

    this.element.requestSubmit(this.submitTarget)
  }
}
