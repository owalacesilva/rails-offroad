module ModerationHelper
  # Cor por situação do anunciante. Semântica, não decorativa: bloqueado tem de
  # se distinguir de inativo à primeira vista na tabela.
  USER_STATUS_STYLES = {
    "active" => "bg-emerald-50 text-emerald-700 ring-emerald-300",
    "inactive" => "bg-stone-100 text-stone-600 ring-stone-300",
    "blocked" => "bg-red-50 text-red-700 ring-red-300"
  }.freeze

  # Situação desconhecida sai cinza em vez de sem classe nenhuma: uma linha
  # gravada por SQL direto não pode desmontar a tabela.
  UNKNOWN_STATUS_STYLE = "bg-stone-100 text-stone-600 ring-stone-300".freeze

  # Ícone e cor do item que leva o anunciante a cada situação, no menu de três
  # pontos da linha. Bloquear sai em vermelho porque tira do ar todos os
  # anúncios da conta de uma vez.
  USER_STATUS_ACTIONS = {
    "active" => { icon: :check, tone: :positive },
    "inactive" => { icon: :pause, tone: :default },
    "blocked" => { icon: :no_symbol, tone: :danger }
  }.freeze

  def user_status_action(status)
    USER_STATUS_ACTIONS.fetch(status, { icon: :user, tone: :default })
  end

  def user_status_badge(user)
    status = user.status

    status_badge(t("admin.users.statuses.#{status}"), USER_STATUS_STYLES.fetch(status, UNKNOWN_STATUS_STYLE))
  end

  # A mesma situação do anúncio, dita no vocabulário de quem modera: o painel do
  # anunciante fala "Publicado" e "Em análise" (ads.statuses, em AdsHelper),
  # enquanto a fila fala "Aprovado" e "Pendente" — as palavras das abas.
  #
  # A cor vem da tabela do AdsHelper em vez de uma cópia daqui: são as mesmas
  # quatro situações, e duas paletas iguais só existem para divergir depois.
  def moderation_status_badge(ad)
    status = ad.status

    status_badge(t("admin.ads.status_labels.#{status}"),
                 AdsHelper::AD_STATUS_STYLES.fetch(status, UNKNOWN_STATUS_STYLE))
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

  private
    def status_badge(label, styles)
      tag.span(
        label,
        class: "inline-block rounded-full px-2.5 py-1 text-[11px] font-bold uppercase tracking-wide " \
               "ring-1 #{styles}"
      )
    end
end
