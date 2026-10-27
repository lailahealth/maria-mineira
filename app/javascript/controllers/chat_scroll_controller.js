import { Controller } from "@hotwired/stimulus"

// Keeps the chat transcript scrolled to the latest message, including messages
// appended later via Turbo Streams (hence the MutationObserver, not just connect()).
// The ResizeObserver re-scrolls when the transcript shrinks, e.g. when the
// phone keyboard opens and chat-viewport resizes the section.
//
// When a reply arrives that doesn't fit on screen (a long answer, usually
// followed by a short "Quando quiser…" hint), jumping to the very end would
// leave the reader at the bottom of the answer; instead the first new reply
// from Maria Mineira is aligned to the top so it reads from its beginning.
export default class extends Controller {
  connect() {
    this.scrollToLatest()
    this.observer = new MutationObserver((records) => this.handleMutations(records))
    this.observer.observe(this.element, { childList: true })
    this.resizeObserver = new ResizeObserver(() => this.keepPosition())
    this.resizeObserver.observe(this.element)
  }

  disconnect() {
    this.observer?.disconnect()
    this.resizeObserver?.disconnect()
  }

  // Only additions matter: the "digitando…" bubble being removed must not undo
  // the anchoring done when the reply arrived.
  handleMutations(records) {
    const added = records.flatMap((record) => [...record.addedNodes])
      .filter((node) => node.nodeType === Node.ELEMENT_NODE)
    if (added.length === 0) return

    const firstReply = added.find((node) => node.id !== "typing-indicator" && !node.classList.contains("justify-end"))
    this.anchor = firstReply && this.overflows(firstReply) ? firstReply : null
    this.keepPosition()
  }

  // Re-applied on resize so the keyboard opening doesn't throw the reader
  // from the start of a long reply to its end.
  keepPosition() {
    if (this.anchor?.isConnected) {
      this.scrollToTopOf(this.anchor)
    } else {
      this.scrollToLatest()
    }
  }

  // On phones a long message (like the greeting) may not fit above the
  // keyboard; show its beginning instead of its end so it can be read.
  scrollToLatest() {
    const latest = this.element.lastElementChild
    if (latest && latest.offsetHeight > this.element.clientHeight) {
      this.scrollToTopOf(latest)
    } else {
      this.element.scrollTop = this.element.scrollHeight
    }
  }

  // Does everything from this node to the end of the transcript fail to fit?
  overflows(node) {
    const contentBottom = this.element.lastElementChild.getBoundingClientRect().bottom
    return contentBottom - node.getBoundingClientRect().top > this.element.clientHeight
  }

  scrollToTopOf(node) {
    const gap = node.getBoundingClientRect().top - this.element.getBoundingClientRect().top
    this.element.scrollTop += gap - 12
  }
}
