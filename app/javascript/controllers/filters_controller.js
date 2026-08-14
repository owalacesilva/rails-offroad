import { Controller } from "@hotwired/stimulus"

// Painel de filtros recolhível: fechado no mobile, aberto a partir de lg (1024px).
// O painel renderiza aberto no HTML, então sem JS o filtro continua utilizável.
export default class extends Controller {
  static targets = ["panel", "toggle", "chevron"]

  connect() {
    this.desktop = window.matchMedia("(min-width: 1024px)")
    this.onBreakpointChange = (event) => this.expand(event.matches)
    this.desktop.addEventListener("change", this.onBreakpointChange)
    this.expand(this.desktop.matches)
  }

  disconnect() {
    this.desktop.removeEventListener("change", this.onBreakpointChange)
  }

  toggle() {
    this.expand(this.panelTarget.classList.contains("hidden"))
  }

  // Cidade pertence a um estado: trocar o estado invalida a escolha anterior.
  resetCity() {
    const city = this.element.querySelector("select[name='city']")
    if (city) city.value = ""
  }

  expand(expanded) {
    this.panelTarget.classList.toggle("hidden", !expanded)

    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute("aria-expanded", String(expanded))
    }

    if (this.hasChevronTarget) {
      this.chevronTarget.classList.toggle("rotate-180", expanded)
    }
  }
}
