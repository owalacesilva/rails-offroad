import { Controller } from "@hotwired/stimulus"

// Menu de ações de uma linha (shared/_row_menu). O <details> já abre, fecha e
// navega por teclado; o que falta é o de sempre — sumir no clique fora e no Esc
// — mais uma coisa que só as tabelas exigem.
//
// As tabelas da moderação vivem dentro de um container com `overflow-x-auto`, e
// pela regra do CSS um eixo não-visible torna o outro `auto` também: o painel
// absoluto seria recortado embaixo da linha. Ao abrir, o controller passa o
// painel para `position: fixed` e o ancora no gatilho, o que o tira do recorte;
// se não houver espaço abaixo, ele abre para cima.
//
// Sem JavaScript o painel continua `absolute`: nas duas tabelas ele fica dentro
// da área que rola, e nas listas de blog e eventos, que não têm container com
// overflow, aparece inteiro.
export default class extends Controller {
  static targets = ["panel"]

  connect() {
    this.closeOnOutsideClick = (event) => {
      if (!this.element.contains(event.target)) this.close()
    }
    this.closeOnEscape = (event) => {
      if (event.key === "Escape") this.close()
    }
    this.replace = () => {
      if (this.element.open) this.place()
    }

    document.addEventListener("click", this.closeOnOutsideClick)
    document.addEventListener("keydown", this.closeOnEscape)
    // O terceiro argumento captura: a tabela rola no container, e um scroll que
    // não chega ao window deixaria o painel parado onde estava.
    window.addEventListener("scroll", this.replace, true)
    window.addEventListener("resize", this.replace)
    this.element.addEventListener("toggle", this.replace)
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnOutsideClick)
    document.removeEventListener("keydown", this.closeOnEscape)
    window.removeEventListener("scroll", this.replace, true)
    window.removeEventListener("resize", this.replace)
    this.element.removeEventListener("toggle", this.replace)
  }

  close() {
    this.element.open = false
  }

  place() {
    const panel = this.panelTarget
    const trigger = this.element.querySelector("summary").getBoundingClientRect()

    panel.style.position = "fixed"
    panel.style.right = "auto"
    // Alinhado pela direita do gatilho, sem passar da borda esquerda da janela.
    panel.style.left = `${Math.max(8, trigger.right - panel.offsetWidth)}px`

    const room = window.innerHeight - trigger.bottom
    panel.style.top = room > panel.offsetHeight + 8
      ? `${trigger.bottom + 4}px`
      : `${Math.max(8, trigger.top - panel.offsetHeight - 4)}px`
  }
}
