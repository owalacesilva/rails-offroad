import { Controller } from "@hotwired/stimulus"

// Capa de evento e de post: um arquivo só, enviado assim que é escolhido.
//
// Diferente do Dropzone das fotos de anúncio, que é fila de vários. Aqui basta
// um <input type="file"> comum: o controller manda o arquivo para o endpoint da
// gestão, guarda o signed_id devolvido num campo escondido e mostra a prévia.
//
// Sem JavaScript sobra o campo de URL, que continua no formulário — é o que o
// seed usa e o que aceita uma imagem já hospedada em outro lugar.
export default class extends Controller {
  static targets = ["input", "signedId", "preview", "image", "remove", "error", "status"]
  static values = { url: String, text: Object }

  connect() {
    this.render(this.imageTarget.getAttribute("src"))
  }

  async selected() {
    const file = this.inputTarget.files[0]
    if (!file) return

    this.errorTarget.textContent = ""
    this.statusTarget.textContent = this.textValue.sending

    const body = new FormData()
    body.append("file", file)

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: { "X-CSRF-Token": this.csrfToken, Accept: "application/json" },
        body,
      })
      const payload = await response.json()

      if (response.ok) this.accepted(payload)
      else this.rejected(payload.error)
    } catch {
      this.rejected(this.textValue.failed)
    } finally {
      this.statusTarget.textContent = ""
    }
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content ?? ""
  }

  accepted(payload) {
    this.signedIdTarget.value = payload.signed_id
    this.render(payload.url)
  }

  rejected(message) {
    this.errorTarget.textContent = message ?? this.textValue.failed
    // O arquivo recusado sai do input: senão o campo mostraria um nome que o
    // servidor não aceitou.
    this.inputTarget.value = ""
  }

  // Tira a capa. O campo escondido vazio é o que diz ao servidor "sem imagem",
  // já que não mandar o parâmetro significaria "não mexi nisso".
  remove() {
    this.signedIdTarget.value = ""
    this.inputTarget.value = ""
    this.render(null)
  }

  render(url) {
    const present = Boolean(url)

    if (present) this.imageTarget.setAttribute("src", url)
    this.previewTarget.hidden = !present
    this.removeTarget.hidden = !present
  }
}
