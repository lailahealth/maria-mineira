import { Controller } from "@hotwired/stimulus"

// Keeps the chat transcript scrolled to the latest message, including messages
// appended later via Turbo Streams (hence the MutationObserver, not just connect()).
// The ResizeObserver re-scrolls when the transcript shrinks, e.g. when the
// phone keyboard opens and chat-viewport resizes the section.
export default class extends Controller {
  connect() {
    this.mobile = window.matchMedia("(max-width: 639px)")
    this.scrollToLatest()
    this.observer = new MutationObserver(() => this.scrollToLatest())
    this.observer.observe(this.element, { childList: true })
    this.resizeObserver = new ResizeObserver(() => this.scrollToLatest())
    this.resizeObserver.observe(this.element)
  }

  disconnect() {
    this.observer?.disconnect()
    this.resizeObserver?.disconnect()
  }

  // On phones a long message (like the greeting) may not fit above the
  // keyboard; show its beginning instead of its end so it can be read.
  scrollToLatest() {
    const latest = this.element.lastElementChild
    if (this.mobile.matches && latest && latest.offsetHeight > this.element.clientHeight) {
      const gap = latest.getBoundingClientRect().top - this.element.getBoundingClientRect().top
      this.element.scrollTop += gap - 12
    } else {
      this.element.scrollTop = this.element.scrollHeight
    }
  }
}
