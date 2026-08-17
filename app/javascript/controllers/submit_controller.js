import { Controller } from "@hotwired/stimulus"

// Estado do botão de publicar: bloqueado enquanto faltam fotos, girando durante
// o envio.
//
// O bloqueio duplica de propósito a validação de 3 a 10 fotos do modelo — ela é
// quem decide, esta aqui só evita que o anunciante descubra o problema depois de
// preencher o formulário inteiro.
export default class extends Controller {
  static targets = ["button", "label", "spinner", "hint"]
  static values = { sending: String }

  connect() {
    this.original = this.labelTarget.textContent
  }

  // Disparado pelo photo-upload a cada foto aceita ou removida.
  photosChanged({ detail }) {
    const ready = detail.count >= detail.min

    this.buttonTarget.disabled = !ready
    this.hintTarget.classList.toggle("hidden", ready)
  }

  // O evento submit só chega aqui depois da validação nativa do navegador, então
  // formulário incompleto não deixa o botão travado girando.
  sending() {
    this.buttonTarget.disabled = true
    this.spinnerTarget.classList.remove("hidden")
    this.labelTarget.textContent = this.sendingValue
  }

  // O Turbo devolve o 422 substituindo o corpo da página, mas uma volta pelo
  // cache (botão "voltar") reexibe o DOM como estava: aí o botão precisa voltar.
  restore() {
    this.buttonTarget.disabled = false
    this.spinnerTarget.classList.add("hidden")
    this.labelTarget.textContent = this.original
  }
}
