import { Controller } from "@hotwired/stimulus"

// Editor mínimo da descrição: negrito, itálico, lista com marcadores, lista
// numerada e título H3 — exatamente os cinco controles pedidos, nada além.
//
// O campo do formulário continua sendo o <textarea>. O controller o esconde,
// põe um contenteditable no lugar e devolve o HTML para ele a cada alteração;
// sem JavaScript o anunciante escreve texto puro e o servidor aceita igual.
// Quem decide o que sobrevive é o Ad#description= no servidor, que só deixa
// passar a lista de tags permitidas — nada aqui é garantia de nada.
//
// document.execCommand é formalmente obsoleto e não tem substituto
// implementado: a Editing API nunca saiu do papel, e é nele que os editores de
// prateleira continuam apoiados.
export default class extends Controller {
  static targets = ["input", "editor", "toolbar", "button"]

  // Estado vazio do contenteditable. Sem o parágrafo inicial o primeiro
  // formatBlock não tem em que bloco agir.
  static EMPTY = "<p><br></p>"

  connect() {
    this.editorTarget.innerHTML = this.inputTarget.value.trim() || this.constructor.EMPTY
    this.inputTarget.classList.add("hidden")
    this.toolbarTarget.classList.remove("hidden")
    this.editorTarget.classList.remove("hidden")
    this.refresh()
  }

  // data-rich-text-command-param traz o comando; H3 traz também o value.
  run({ params }) {
    this.editorTarget.focus()
    document.execCommand(params.command, false, params.value ?? null)
    this.sync()
  }

  sync() {
    const html = this.editorTarget.innerHTML

    this.inputTarget.value = html === this.constructor.EMPTY ? "" : html
    this.refresh()
  }

  // Colar de um editor de texto traria estilo inline e tags que o servidor
  // descartaria depois; entra como texto puro e o anunciante formata aqui.
  paste(event) {
    event.preventDefault()
    document.execCommand("insertText", false, event.clipboardData.getData("text/plain"))
    this.sync()
  }

  // O botão do controle ativo no cursor fica marcado, como em qualquer editor.
  refresh() {
    this.buttonTargets.forEach((button) => {
      const { command, value } = button.dataset.richTextCommandParam
        ? { command: button.dataset.richTextCommandParam, value: button.dataset.richTextValueParam }
        : {}
      if (!command) return

      button.setAttribute("aria-pressed", String(this.active(command, value)))
    })
  }

  active(command, value) {
    try {
      if (command === "formatBlock") {
        return document.queryCommandValue("formatBlock").toLowerCase() === (value || "").toLowerCase()
      }
      return document.queryCommandState(command)
    } catch {
      return false
    }
  }
}
