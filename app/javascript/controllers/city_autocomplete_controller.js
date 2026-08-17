import { Controller } from "@hotwired/stimulus"

// Autocomplete de município. Pede ao servidor só os da UF escolhida e só os que
// casam com o que já foi digitado — os 5.571 municípios do país nunca chegam ao
// navegador de uma vez, que é o ponto do endpoint /municipios.
//
// A lista é um <datalist> nativo: sem JavaScript o campo segue sendo um texto
// comum, que é exatamente o que o servidor grava (ads.city é string).
export default class extends Controller {
  static targets = ["state", "city", "list"]
  static values = {
    url: String,
    // Folga entre teclas: sem ela seria uma requisição por caractere.
    delay: { type: Number, default: 200 },
  }

  connect() {
    this.pending = null
    if (this.stateTarget.value) this.search()
  }

  disconnect() {
    clearTimeout(this.timer)
    this.pending?.abort()
  }

  // Cidade pertence a um estado: trocar a UF invalida a escolha anterior.
  stateChanged() {
    this.cityTarget.value = ""
    this.search()
  }

  typed() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.search(), this.delayValue)
  }

  async search() {
    const state = this.stateTarget.value
    if (!state) return this.render([])

    // Resposta antiga chegando depois da nova deixaria a lista errada na tela.
    this.pending?.abort()
    this.pending = new AbortController()

    const params = new URLSearchParams({ state, q: this.cityTarget.value })

    try {
      const response = await fetch(`${this.urlValue}?${params}`, {
        headers: { Accept: "application/json" },
        signal: this.pending.signal,
      })
      if (response.ok) this.render(await response.json())
    } catch (error) {
      // Busca cancelada não é falha: só a próxima é que vale.
      if (error.name !== "AbortError") this.render([])
    }
  }

  render(names) {
    this.listTarget.replaceChildren(
      ...names.map((name) => {
        const option = document.createElement("option")
        option.value = name
        return option
      })
    )
  }
}
