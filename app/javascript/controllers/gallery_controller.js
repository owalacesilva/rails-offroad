import { Controller } from "@hotwired/stimulus"

// Troca a foto principal ao clicar numa miniatura. Sem JS a foto principal
// continua visível — só a troca deixa de funcionar.
export default class extends Controller {
  static targets = ["main", "thumb"]

  select({ params: { url, alt }, currentTarget }) {
    this.mainTarget.src = url
    this.mainTarget.alt = alt

    this.thumbTargets.forEach((thumb) => {
      const selected = thumb === currentTarget
      thumb.classList.toggle("ring-brand-500", selected)
      thumb.classList.toggle("ring-stone-700", !selected)
      thumb.setAttribute("aria-current", selected ? "true" : "false")
    })
  }
}
