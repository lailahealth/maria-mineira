import { Controller } from "@hotwired/stimulus"

// Mostra uma bolha "digitando…" enquanto aguarda a resposta de uma mensagem do chat.
// A resposta de texto livre agora pode depender de uma chamada de IA (Chat::KnowledgeAnswerer),
// que leva alguns segundos — sem feedback, a tela fica parada e parece travada.
// Turbo já envia o formulário via fetch (sem recarregar a página); isso só cobre o
// tempo de espera visualmente. Escuta em document porque o botão de geolocalização
// (geolocation_controller.js) monta e envia um <form> fora do #composer.
export default class extends Controller {
  static values = { id: { type: String, default: "typing-indicator" } }

  start(event) {
    if (!this.isChatMessageForm(event.target)) return
    if (document.getElementById(this.idValue)) return

    const bubble = document.createElement("div")
    bubble.id = this.idValue
    bubble.className = "flex justify-start gap-2"
    bubble.setAttribute("aria-live", "polite")
    bubble.setAttribute("aria-label", "Maria Mineira está digitando")
    bubble.innerHTML = `
      <div class="flex size-7 shrink-0 items-center justify-center rounded-full bg-vinho font-display text-xs font-semibold text-offwhite" aria-hidden="true">M</div>
      <div class="flex items-center gap-1 rounded-2xl rounded-bl-sm bg-blush/40 px-4 py-3">
        <span class="size-1.5 animate-bounce rounded-full bg-presenca/40 [animation-delay:-0.3s]"></span>
        <span class="size-1.5 animate-bounce rounded-full bg-presenca/40 [animation-delay:-0.15s]"></span>
        <span class="size-1.5 animate-bounce rounded-full bg-presenca/40"></span>
      </div>
    `

    this.element.appendChild(bubble)
  }

  end(event) {
    if (!this.isChatMessageForm(event.target)) return

    document.getElementById(this.idValue)?.remove()
  }

  isChatMessageForm(form) {
    return form instanceof HTMLFormElement && /\/mensagens(\?|$)/.test(form.action)
  }
}
