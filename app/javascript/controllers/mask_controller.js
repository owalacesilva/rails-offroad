import { Controller } from "@hotwired/stimulus"

// Máscara de digitação. Dois formatos, os dois brasileiros:
//
//   currency -> 45.000,50          (a vírgula decimal que o servidor já sabe ler)
//   phone    -> (11) 9 8765-4321   e (11) 3456-7890 para o fixo de 8 dígitos
//
// É conforto de digitação, não validação: quem normaliza de verdade é o modelo
// (User.normalize_phone, ApplicationRecord.to_cents), porque nada que chega do
// navegador conta como garantia. Sem JavaScript o campo aceita o mesmo texto.
export default class extends Controller {
  static values = { type: String }

  // Reformatar recoloca o cursor no fim. Aceitável enquanto se digita à direita,
  // que é o caso das duas máscaras; editar no meio do número puxa o cursor.
  connect() {
    this.format()
  }

  format() {
    const digits = this.element.value.replace(/\D/g, "")

    this.element.value = this.typeValue === "phone" ? this.phone(digits) : this.currency(digits)
  }

  // Os dígitos são lidos como centavos: digitar 4500050 mostra 45.000,50.
  currency(digits) {
    if (!digits) return ""

    const cents = digits.slice(0, 11).padStart(3, "0")
    const units = cents.slice(0, -2).replace(/^0+(?=\d)/, "")

    return `${units.replace(/\B(?=(\d{3})+(?!\d))/g, ".")},${cents.slice(-2)}`
  }

  phone(digits) {
    const trimmed = digits.slice(0, 11)
    const area = trimmed.slice(0, 2)
    const rest = trimmed.slice(2)

    if (!area) return ""
    if (!rest) return `(${area}`
    if (rest.length <= 4) return `(${area}) ${rest}`
    // Oito dígitos é fixo; nove começa com o 9 e ganha o espaço depois dele.
    if (rest.length <= 8) return `(${area}) ${rest.slice(0, 4)}-${rest.slice(4)}`

    return `(${area}) ${rest.slice(0, 1)} ${rest.slice(1, 5)}-${rest.slice(5)}`
  }
}
