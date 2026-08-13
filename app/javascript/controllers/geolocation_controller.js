import { Controller } from "@hotwired/stimulus"

// Requests the browser Geolocation API and submits the result as a normal Turbo
// form submission — no fetch/JSON plumbing needed, Turbo handles the turbo_stream response.
export default class extends Controller {
  static values = { url: String }
  static targets = ["button", "label", "error"]

  request() {
    if (!("geolocation" in navigator)) {
      this.showError("Seu navegador não permite compartilhar localização. Use o campo de município abaixo.")
      return
    }

    this.buttonTarget.disabled = true
    this.labelTarget.textContent = "Obtendo localização…"

    navigator.geolocation.getCurrentPosition(
      (position) => this.submit(position.coords.latitude, position.coords.longitude),
      () => {
        this.buttonTarget.disabled = false
        this.labelTarget.textContent = "Usar minha localização"
        this.showError("Não conseguimos acessar sua localização. Use o campo de município abaixo.")
      },
      { enableHighAccuracy: false, timeout: 8000 }
    )
  }

  submit(lat, lng) {
    const form = document.createElement("form")
    form.method = "post"
    form.action = this.urlValue
    form.style.display = "none"

    const csrf = document.querySelector('meta[name="csrf-token"]')
    if (csrf) form.appendChild(this.hiddenField("authenticity_token", csrf.content))
    form.appendChild(this.hiddenField("lat", lat))
    form.appendChild(this.hiddenField("lng", lng))

    document.body.appendChild(form)
    form.requestSubmit()
  }

  hiddenField(name, value) {
    const input = document.createElement("input")
    input.type = "hidden"
    input.name = name
    input.value = value
    return input
  }

  showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
  }
}
