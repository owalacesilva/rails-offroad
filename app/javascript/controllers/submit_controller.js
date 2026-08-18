import { Controller } from "@hotwired/stimulus"

// Estado do botão de publicar: bloqueado enquanto faltar foto ou especificação,
// girando durante o envio.
//
// O bloqueio duplica de propósito validações que o modelo já faz — são elas que
// decidem. Aqui é só para o anunciante não descobrir o problema depois de
// preencher o formulário inteiro.
//
// Este controller vem antes de "category-specs" no data-controller do form, e o
// form é ancestral do photo-upload: as duas coisas garantem que ele já esteja
// conectado quando os dois disparam o primeiro evento no connect deles.
export default class extends Controller {
  static targets = ["button", "label", "spinner", "photosHint", "specsHint"]
  static values = { sending: String }

  connect() {
    this.original = this.labelTarget.textContent
    // Nada verificado ainda: o botão nasce desabilitado no HTML e só destrava
    // quando os dois avisarem que estão completos.
    this.ready = { photos: false, specs: false }
  }

  // Disparado pelo photo-upload a cada foto aceita ou removida.
  photosChanged({ detail }) {
    this.ready.photos = detail.count >= detail.min
    this.photosHintTarget.classList.toggle("hidden", this.ready.photos)
    this.refresh()
  }

  // Disparado pelo category-specs a cada campo do modal preenchido ou limpo.
  specsChanged({ detail }) {
    this.ready.specs = detail.filled >= detail.total
    this.specsHintTarget.classList.toggle("hidden", this.ready.specs)
    this.refresh()
  }

  refresh() {
    this.buttonTarget.disabled = !(this.ready.photos && this.ready.specs)
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
    this.spinnerTarget.classList.add("hidden")
    this.labelTarget.textContent = this.original
    this.refresh()
  }
}
