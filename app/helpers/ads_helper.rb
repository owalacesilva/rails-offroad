module AdsHelper
  # A unidade é fixa (o portal negocia em BRL em qualquer idioma), mas separadores
  # e espaçamento seguem o locale via rails-i18n — daí "R$" sem espaço à direita:
  # o format do pt-BR ("%u %n") já insere o separador.
  def ad_price(amount)
    number_to_currency(amount, unit: "R$", precision: 0)
  end

  # Mantém os filtros atuais ao trocar de página.
  def ads_page_path(page)
    ads_path(request.query_parameters.merge(page: page))
  end

  # wa.me exige o telefone só com dígitos e código do país (validado em User).
  def whatsapp_url(ad)
    message = t("ads.show.whatsapp_message", title: ad.title, url: ad_url(ad))

    "https://wa.me/#{ad.user.phone}?text=#{CGI.escape(message)}"
  end

  # Chave sem tradução cai no próprio nome humanizado em vez de "translation missing".
  def specification_label(key)
    t("ads.specifications.#{key}", default: key.to_s.humanize)
  end

  def specification_value(key, value)
    return "#{number_with_delimiter(value)} km" if key.to_s == "mileage_km"

    value.to_s
  end

  # Cor por situação de moderação. Semântica, não decorativa: aprovado e
  # rejeitado precisam se distinguir de relance na lista do anunciante.
  AD_STATUS_STYLES = {
    "draft" => "bg-stone-100 text-stone-600 ring-stone-300",
    "pending" => "bg-amber-50 text-amber-700 ring-amber-300",
    "approved" => "bg-emerald-50 text-emerald-700 ring-emerald-300",
    "rejected" => "bg-red-50 text-red-700 ring-red-300"
  }.freeze

  def ad_status_badge(status)
    tag.span(
      t("ads.statuses.#{status}"),
      class: "inline-block rounded-full px-2.5 py-1 text-[11px] font-bold uppercase tracking-wide " \
             "ring-1 #{AD_STATUS_STYLES.fetch(status, AD_STATUS_STYLES['draft'])}"
    )
  end

  # Acima disso a régua numerada fica ilegível e sobra só anterior/próxima.
  MAX_NUMBERED_PAGES = 9

  def paginated_page_numbers(pagination)
    total = pagination.total_pages
    return [] if total > MAX_NUMBERED_PAGES

    (1..total).to_a
  end
end
