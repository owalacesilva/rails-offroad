module ModerationHelper
  # Cor por situação do anunciante. Semântica, não decorativa: bloqueado tem de
  # se distinguir de inativo à primeira vista na tabela.
  USER_STATUS_STYLES = {
    "active" => "bg-emerald-50 text-emerald-700 ring-emerald-300",
    "inactive" => "bg-stone-100 text-stone-600 ring-stone-300",
    "blocked" => "bg-red-50 text-red-700 ring-red-300"
  }.freeze

  def user_status_badge(user)
    status = user.status

    tag.span(
      t("admin.users.statuses.#{status}"),
      class: "inline-block rounded-full px-2.5 py-1 text-[11px] font-bold uppercase tracking-wide " \
             "ring-1 #{USER_STATUS_STYLES.fetch(status, USER_STATUS_STYLES['inactive'])}"
    )
  end

  # "5541988770011" -> "(41) 9 8877-0011". A coluna guarda só dígitos com código
  # do país (é o que o link do wa.me exige); a tabela mostra no formato de quem
  # lê. Número fora do formato esperado sai como está, sem inventar máscara.
  def admin_phone(digits)
    local = digits.to_s.delete_prefix("55")
    area = local[0, 2]
    rest = local[2..].to_s
    length = rest.length

    return digits if area.blank? || length < 8

    length > 8 ? "(#{area}) #{rest[0]} #{rest[1, 4]}-#{rest[5..]}" : "(#{area}) #{rest[0, 4]}-#{rest[4..]}"
  end
end
