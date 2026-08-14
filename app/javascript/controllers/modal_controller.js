import { Controller } from "@hotwired/stimulus"

// Usa o <dialog> nativo, que já traz fechamento com Esc e prisão de foco.
export default class extends Controller {
  static targets = ["dialog"]
  static values = { open: Boolean }

  connect() {
    // Reabre sozinho quando o servidor devolve o formulário com erro de validação.
    if (this.openValue) this.open()
  }

  open() {
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  // O <dialog> reporta o clique no backdrop como se fosse nele próprio.
  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }
}
