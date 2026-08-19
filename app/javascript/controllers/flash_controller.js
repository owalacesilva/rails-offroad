import { Controller } from "@hotwired/stimulus"
import Swal from "sweetalert2"

// Todo feedback do servidor vira modal. As mensagens chegam no data-attribute
// que shared/_flash escreve, e o elemento é removido antes de abrir qualquer
// coisa: o Turbo guarda a página no cache ao sair dela, e um aviso que ficasse
// no DOM voltaria a aparecer quando o visitante apertasse "voltar".
//
// Sem JavaScript nada disto roda e o <noscript> do mesmo partial mostra a faixa.
export default class extends Controller {
  static values = { messages: Object, confirm: String }

  connect() {
    const messages = Object.entries(this.messagesValue)

    this.element.remove()

    // Um modal por vez: o SweetAlert só mantém um aberto, então a fila anda
    // encadeada na promessa do anterior. Na prática é quase sempre um só.
    messages.reduce(
      (queue, [type, text]) => queue.then(() => this.fire(type, text)),
      Promise.resolve()
    )
  }

  fire(type, text) {
    return Swal.fire({
      text: text,
      icon: type === "alert" ? "error" : "success",
      confirmButtonText: this.confirmValue,
      // O botão é vestido pelo CSS do portal (ver .swal2-* no arquivo do
      // Tailwind); o estilo que vem no pacote sairia de outra paleta.
      buttonsStyling: false
    })
  }
}
