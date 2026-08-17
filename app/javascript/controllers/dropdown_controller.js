import { Controller } from "@hotwired/stimulus"

// Complementa o <details> de shared/_dropdown. Abrir, fechar e navegar por
// teclado já são nativos; o que falta é o comportamento de menu: sumir quando o
// clique vai para outro lugar da página ou quando o Esc é pressionado.
// Os ouvintes ficam no document, então são removidos no disconnect — o Turbo
// troca o body a cada navegação e eles se acumulariam.
export default class extends Controller {
  connect() {
    this.closeOnOutsideClick = (event) => {
      if (!this.element.contains(event.target)) this.close()
    }
    this.closeOnEscape = (event) => {
      if (event.key === "Escape") this.close()
    }

    document.addEventListener("click", this.closeOnOutsideClick)
    document.addEventListener("keydown", this.closeOnEscape)
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnOutsideClick)
    document.removeEventListener("keydown", this.closeOnEscape)
  }

  close() {
    this.element.open = false
  }
}
