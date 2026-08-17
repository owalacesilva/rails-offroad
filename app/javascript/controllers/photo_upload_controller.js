import { Controller } from "@hotwired/stimulus"
import Dropzone from "dropzone"

// Envio das fotos do anúncio, uma requisição por arquivo.
//
// Cada upload vai para /anunciante/anuncios/fotos e volta com o signed_id de um
// blob do Active Storage; o controller guarda esses ids em inputs escondidos, na
// ordem da fila, e é essa ordem que vira o sort_order das fotos.
//
// O redimensionamento acontece aqui, antes de subir: resizeMethod "contain" faz
// a imagem caber na caixa máxima sem distorcer e, como o Dropzone nunca amplia,
// foto menor que o limite sobe intacta. O servidor recusa o que passar do
// limite de qualquer forma — nada que vem do navegador vale como garantia.
export default class extends Controller {
  static targets = ["zone", "previews", "inputs", "counter", "fallback", "template", "existing"]
  static values = {
    url: String,
    min: Number,
    max: Number,
    width: Number,
    height: Number,
    maxBytes: Number,
    // Rótulos traduzidos: o controller não conhece o idioma da página.
    text: Object,
  }

  connect() {
    this.fallbackTarget.classList.add("hidden")
    this.zoneTarget.classList.remove("hidden")

    this.dropzone = new Dropzone(this.zoneTarget, this.options())
    this.dropzone.on("success", (file, body) => this.accepted(file, body))
    this.dropzone.on("error", (file, message) => this.rejected(file, message))
    this.dropzone.on("removedfile", () => this.sync())
    this.sync()
  }

  disconnect() {
    this.dropzone?.destroy()
  }

  options() {
    return {
      url: this.urlValue,
      paramName: "file",
      maxFiles: this.maxValue,
      maxFilesize: this.maxBytesValue / (1024 * 1024),
      acceptedFiles: "image/jpeg,image/png,image/webp",
      resizeWidth: this.widthValue,
      resizeHeight: this.heightValue,
      resizeMethod: "contain",
      resizeQuality: 0.9,
      addRemoveLinks: false,
      previewTemplate: this.templateTarget.innerHTML,
      // Miniaturas em uma grade própria, fora da área de soltar: dentro dela
      // as fotos empurrariam a mensagem "arraste aqui" para fora da vista.
      previewsContainer: this.previewsTarget,
      dictDefaultMessage: this.textValue.prompt,
      dictMaxFilesExceeded: this.textValue.tooMany,
      dictInvalidFileType: this.textValue.type,
      dictFileTooBig: this.textValue.tooBig,
      headers: { "X-CSRF-Token": this.csrfToken },
    }
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content ?? ""
  }

  accepted(file, body) {
    file.signedId = body.signed_id
    this.sync()
  }

  // O servidor responde { error: "..." } com 422; sem isso o Dropzone mostraria
  // o corpo JSON cru embaixo da miniatura.
  rejected(file, message) {
    const text = typeof message === "string" ? message : message?.error

    if (file.previewElement) {
      const slot = file.previewElement.querySelector("[data-dz-errormessage]")
      if (slot) slot.textContent = text ?? this.textValue.failed
    }
    this.sync()
  }

  // Botão de remover do preview do Dropzone.
  remove(event) {
    const preview = event.target.closest(".dz-preview")
    const file = this.dropzone.files.find((candidate) => candidate.previewElement === preview)

    if (file) this.dropzone.removeFile(file)
  }

  // Botão de remover de uma foto que já tinha subido antes do formulário voltar
  // com erro: ela é HTML do servidor, não um arquivo do Dropzone.
  removeExisting(event) {
    event.target.closest("[data-photo]")?.remove()
    this.sync()
  }

  // Reescreve os inputs escondidos a cada mudança. A ordem dos inputs no
  // formulário é a ordem das fotos na galeria, e as que já tinham subido vêm
  // primeiro — remover a segunda renumera as seguintes sozinho, no servidor.
  sync() {
    const ids = this.dropzone.files.map((file) => file.signedId).filter(Boolean)

    this.inputsTarget.replaceChildren(
      ...ids.map((id) => {
        const input = document.createElement("input")
        input.type = "hidden"
        input.name = "photo_signed_ids[]"
        input.value = id
        return input
      })
    )

    const count = ids.length + this.existingTarget.querySelectorAll("[data-photo]").length

    this.counterTarget.textContent = this.textValue.counter
      .replace("%{count}", count)
      .replace("%{min}", this.minValue)
      .replace("%{max}", this.maxValue)

    // O botão de publicar escuta este evento e só libera com o mínimo de fotos.
    this.dispatch("change", { detail: { count, min: this.minValue } })
  }
}
