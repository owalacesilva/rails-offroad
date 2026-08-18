import { Controller } from "@hotwired/stimulus"

// Caixas de seleção da tabela de anunciantes.
//
// A barra de ações em lote só aparece quando há linha marcada, e o botão do
// cabeçalho marca ou desmarca a página inteira. O formulário em lote é irmão da
// tabela, não pai: uma <table> não pode ficar dentro de <form> sem quebrar o
// HTML, então as caixas ganham `form="..."` apontando para ele.
export default class extends Controller {
  static targets = ["all", "row", "bar", "count"]
  static values = { text: String }

  connect() {
    this.refresh()
  }

  toggleAll() {
    this.rowTargets.forEach((row) => { row.checked = this.allTarget.checked })
    this.refresh()
  }

  refresh() {
    const checked = this.rowTargets.filter((row) => row.checked)

    // Indeterminado quando só parte da página está marcada: é o estado que o
    // usuário espera ver no cabeçalho.
    this.allTarget.checked = checked.length > 0 && checked.length === this.rowTargets.length
    this.allTarget.indeterminate = checked.length > 0 && checked.length < this.rowTargets.length

    this.barTarget.hidden = checked.length === 0
    this.countTarget.textContent = this.textValue.replace("%{count}", checked.length)
  }

  clear() {
    this.rowTargets.forEach((row) => { row.checked = false })
    this.refresh()
  }
}
