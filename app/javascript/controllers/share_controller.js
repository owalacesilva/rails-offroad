import { Controller } from "@hotwired/stimulus"

// Compartilhar o anúncio.
//
// Os links de rede são âncoras comuns, montadas no servidor: funcionam sem
// JavaScript. Este controller só acrescenta o que depende dele — o
// compartilhamento nativo do sistema, no celular, e o copiar link.
export default class extends Controller {
  static targets = ["native", "copy", "copyLabel"]
  static values = { url: String, title: String, copied: String }

  connect() {
    this.original = this.copyLabelTarget.textContent

    // navigator.share praticamente só existe em toque; no desktop o botão
    // sumiria sem uso, então ele nasce escondido e aparece se houver suporte.
    //
    // A classe de display entra aqui, e não no HTML, porque `hidden` e
    // `inline-flex` disputariam a mesma propriedade e quem vence depende da
    // ordem em que o Tailwind as escreve. Quem não pode aparecer sai do DOM.
    if (navigator.share) {
      this.nativeTarget.classList.remove("hidden")
      this.nativeTarget.classList.add("inline-flex")
    }

    if (!navigator.clipboard) this.copyTarget.remove()
  }

  async native() {
    try {
      await navigator.share({ title: this.titleValue, url: this.urlValue })
    } catch {
      // Cancelar o diálogo do sistema estoura AbortError. Não é erro.
    }
  }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.urlValue)
      this.confirm()
    } catch {
      // Sem permissão de área de transferência não há o que fazer além de
      // deixar o link à vista na barra de endereços.
    }
  }

  confirm() {
    clearTimeout(this.timer)
    this.copyLabelTarget.textContent = this.copiedValue
    this.timer = setTimeout(() => { this.copyLabelTarget.textContent = this.original }, 2000)
  }
}
