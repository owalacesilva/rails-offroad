import { Controller } from "@hotwired/stimulus"

// Especificações técnicas do anúncio, preenchidas num modal.
//
// Os campos ficam dentro do <dialog>, que por sua vez está dentro do formulário:
// diálogo fechado é `display: none`, e campo escondido continua sendo enviado —
// só campo `disabled` fica de fora. É disso que este controller se aproveita
// para manter no envio apenas o bloco da categoria escolhida.
//
// Por isso também nenhum campo aqui é `required`: o Chrome recusa submeter um
// formulário com campo obrigatório que não dá para focar, e é exatamente o que
// um obrigatório dentro de diálogo fechado seria. Quem cobra é o modelo, no
// contexto :submission, com o botão de publicar travado até o conjunto fechar.
export default class extends Controller {
  static targets = ["group", "empty", "open", "summary", "chips", "counter", "modalTitle"]
  static values = { text: Object }

  connect() {
    this.show(this.selected)
  }

  // Trocar de categoria troca o conjunto exigido: o bloco anterior é desligado.
  changed() {
    this.show(this.selected)
  }

  // Digitar em qualquer campo do modal recalcula o resumo e o contador.
  edited() {
    this.refresh()
  }

  get selected() {
    return this.element.querySelector("input[name='ad[category_id]']:checked")?.value
  }

  get activeGroup() {
    return this.groupTargets.find((group) => !group.hidden)
  }

  get fields() {
    return this.activeGroup ? Array.from(this.activeGroup.querySelectorAll("input")) : []
  }

  show(categoryId) {
    this.groupTargets.forEach((group) => {
      const active = String(group.dataset.categoryId) === String(categoryId)

      // `hidden` no lugar de classe: aqui a única regra é esconder, e a
      // propriedade do elemento é o que `activeGroup` consulta depois.
      group.hidden = !active
      group.querySelectorAll("input").forEach((field) => { field.disabled = !active })
    })

    this.refresh()
  }

  refresh() {
    const fields = this.fields
    const filled = fields.filter((field) => field.value.trim() !== "")
    const chosen = Boolean(this.activeGroup)

    this.emptyTarget.hidden = chosen
    this.openTarget.hidden = !chosen
    this.summaryTarget.hidden = !chosen

    if (chosen) this.describe(fields, filled)

    // O botão de publicar escuta isto, como já escuta o envio de fotos.
    this.dispatch("change", { detail: { filled: filled.length, total: fields.length } })
  }

  describe(fields, filled) {
    this.counterTarget.textContent = this.textValue.counter
      .replace("%{count}", filled.length)
      .replace("%{total}", fields.length)

    this.openTarget.textContent = filled.length ? this.textValue.edit : this.textValue.fill
    if (this.hasModalTitleTarget) this.modalTitleTarget.textContent = this.activeGroup.dataset.categoryName

    // Um resumo do que já foi preenchido, para não obrigar a reabrir o modal
    // só para conferir.
    this.chipsTarget.replaceChildren(
      ...filled.map((field) => {
        const chip = document.createElement("span")
        chip.className =
          "inline-flex items-center gap-1 rounded-full bg-stone-100 px-2.5 py-1 text-[11px] font-semibold text-stone-600"
        chip.textContent = `${field.dataset.label}: ${field.value.trim()}`
        return chip
      })
    )
  }
}
