module ModerationHelper
  # Cor por situação do anunciante. Semântica, não decorativa: bloqueado tem de
  # se distinguir de inativo à primeira vista na lista.
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
end
