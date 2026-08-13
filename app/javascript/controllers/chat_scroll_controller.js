import { Controller } from "@hotwired/stimulus"

// Keeps the chat transcript scrolled to the latest message, including messages
// appended later via Turbo Streams (hence the MutationObserver, not just connect()).
export default class extends Controller {
  connect() {
    this.scrollToBottom()
    this.observer = new MutationObserver(() => this.scrollToBottom())
    this.observer.observe(this.element, { childList: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }
}
