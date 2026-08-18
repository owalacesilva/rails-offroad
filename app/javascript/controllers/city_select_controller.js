import { Controller } from "@hotwired/stimulus"

// Seletor de município: um botão que abre um menu com busca própria dentro.
//
// Duas fontes, escolhidas pela presença de `url`:
//
//   com url  — busca no servidor por UF e termo (/municipios). É o caso dos
//              formulários, onde os 5.571 municípios não podem vir de uma vez.
//   sem url  — filtra no próprio navegador a lista já renderizada no <script>.
//              É o caso do filtro da vitrine, cujas opções são as cidades que
//              de fato têm anúncio.
//
// O valor continua no campo de texto original, que o controller esconde: sem
// JavaScript sobra um campo comum, que é o que o servidor grava de qualquer
// jeito (ads.city e users.city são string).
export default class extends Controller {
  static targets = ["field", "button", "label", "panel", "search", "list", "empty", "options"]
  static values = {
    url: String,
    delay: { type: Number, default: 200 },
    text: Object,
  }

  connect() {
    this.pending = null
    this.hideField()
    this.buttonTarget.hidden = false
    this.render()

    this.onOutsideClick = (event) => { if (!this.element.contains(event.target)) this.close() }
    document.addEventListener("click", this.onOutsideClick)

    // A UF não é descendente deste controller — está noutra coluna do mesmo
    // formulário —, então a ligação é por atributo, não por escopo do Stimulus.
    this.onStateChange = () => this.stateChanged()
    this.stateSelect = this.element.closest("form")?.querySelector("[data-city-select-state]")
    this.stateSelect?.addEventListener("change", this.onStateChange)
  }

  disconnect() {
    clearTimeout(this.timer)
    this.pending?.abort()
    document.removeEventListener("click", this.onOutsideClick)
    this.stateSelect?.removeEventListener("change", this.onStateChange)
  }

  // O campo vira invisível, mas continua renderizado: `display: none` o tiraria
  // da validação do navegador e um `required` vazio faria o Chrome recusar o
  // envio em silêncio, reclamando de um campo que não dá para focar. Recortado
  // pelo sr-only ele continua focável, então a mensagem nativa ainda aparece.
  //
  // O rótulo passa a apontar para o botão: quem navega por leitor de tela ouve
  // um controle só, o que de fato existe na tela.
  hideField() {
    const field = this.fieldTarget

    this.element.querySelectorAll(`label[for="${field.id}"]`).forEach((label) => {
      label.htmlFor = this.buttonTarget.id
    })

    field.className = "sr-only"
    field.tabIndex = -1
    field.setAttribute("aria-hidden", "true")
  }

  toggle() {
    this.panelTarget.hidden ? this.open() : this.close()
  }

  open() {
    this.panelTarget.hidden = false
    this.buttonTarget.setAttribute("aria-expanded", "true")
    this.searchTarget.value = ""
    this.searchTarget.focus()
    this.load()
  }

  close() {
    this.panelTarget.hidden = true
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }

  // Esc fecha e devolve o foco ao botão, como em qualquer menu.
  closeOnEscape(event) {
    if (event.key !== "Escape") return

    this.close()
    this.buttonTarget.focus()
  }

  typed() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.load(), this.urlValue ? this.delayValue : 0)
  }

  // Trocar a UF invalida o município escolhido: ele pertence a um estado.
  stateChanged() {
    this.fieldTarget.value = ""
    this.render()

    if (!this.panelTarget.hidden) this.load()
  }

  choose(event) {
    this.fieldTarget.value = event.currentTarget.dataset.city
    this.render()
    this.close()
    this.buttonTarget.focus()
  }

  clear() {
    this.fieldTarget.value = ""
    this.render()
    this.close()
  }

  load() {
    this.urlValue ? this.fetchOptions() : this.filterEmbedded()
  }

  async fetchOptions() {
    const state = this.stateSelect?.value

    if (!state) return this.draw([], this.textValue.choose_state)

    // Resposta antiga chegando depois da nova deixaria a lista errada na tela.
    this.pending?.abort()
    this.pending = new AbortController()

    const params = new URLSearchParams({ state: state, q: this.searchTarget.value })

    try {
      const response = await fetch(`${this.urlValue}?${params}`, {
        headers: { Accept: "application/json" },
        signal: this.pending.signal,
      })

      if (response.ok) this.draw(await response.json())
    } catch (error) {
      if (error.name !== "AbortError") this.draw([])
    }
  }

  filterEmbedded() {
    const term = this.normalize(this.searchTarget.value)
    const all = JSON.parse(this.optionsTarget.textContent)

    this.draw(term ? all.filter((name) => this.normalize(name).includes(term)) : all)
  }

  // Busca sem acento e sem caixa, como a collation do banco faz do outro lado.
  normalize(text) {
    return text.trim().normalize("NFD").replace(/\p{Diacritic}/gu, "").toLowerCase()
  }

  draw(names, emptyMessage) {
    this.emptyTarget.textContent = emptyMessage ?? this.textValue.empty
    this.emptyTarget.hidden = names.length > 0

    this.listTarget.replaceChildren(...names.map((name) => this.option(name)))
  }

  option(name) {
    const chosen = name === this.fieldTarget.value
    const item = document.createElement("li")
    const button = document.createElement("button")

    button.type = "button"
    button.dataset.city = name
    button.dataset.action = "city-select#choose"
    button.setAttribute("role", "option")
    button.setAttribute("aria-selected", String(chosen))
    button.className = `flex w-full cursor-pointer items-center justify-between gap-2 px-4 py-2 text-left text-sm transition hover:bg-stone-50 ${
      chosen ? "font-bold text-brand-600" : "text-stone-700"
    }`
    button.textContent = name

    item.appendChild(button)
    return item
  }

  render() {
    const value = this.fieldTarget.value

    this.labelTarget.textContent = value || this.textValue.placeholder
    this.labelTarget.classList.toggle("text-stone-400", !value)
    this.labelTarget.classList.toggle("text-stone-900", Boolean(value))
  }
}
