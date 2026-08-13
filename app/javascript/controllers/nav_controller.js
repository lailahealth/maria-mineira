import { Controller } from "@hotwired/stimulus"

// Toggles the mobile navigation panel in the site header.
export default class extends Controller {
  static targets = ["panel", "openIcon", "closeIcon"]

  toggle() {
    this.panelTarget.classList.toggle("hidden")
    this.openIconTarget.classList.toggle("hidden")
    this.closeIconTarget.classList.toggle("hidden")
  }
}
