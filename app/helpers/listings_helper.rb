module ListingsHelper
  # A unidade é fixa (o portal negocia em BRL em qualquer idioma), mas separadores
  # e espaçamento seguem o locale via rails-i18n — daí "R$" sem espaço à direita:
  # o format do pt-BR ("%u %n") já insere o separador.
  def listing_price(amount)
    number_to_currency(amount, unit: "R$", precision: 0)
  end

  # Mantém os filtros atuais ao trocar de página.
  def listings_page_path(page)
    listings_path(request.query_parameters.merge(page: page))
  end

  # wa.me exige o telefone só com dígitos e código do país (validado em Advertiser).
  def whatsapp_url(listing)
    message = t("listings.show.whatsapp_message", title: listing.title, url: listing_url(listing))

    "https://wa.me/#{listing.advertiser.phone}?text=#{CGI.escape(message)}"
  end

  # Chave sem tradução cai no próprio nome humanizado em vez de "translation missing".
  def specification_label(key)
    t("listings.specifications.#{key}", default: key.to_s.humanize)
  end

  def specification_value(key, value)
    return "#{number_with_delimiter(value)} km" if key.to_s == "mileage_km"

    value.to_s
  end

  # Acima disso a régua numerada fica ilegível e sobra só anterior/próxima.
  MAX_NUMBERED_PAGES = 9

  def paginated_page_numbers(pagination)
    total = pagination.total_pages
    return [] if total > MAX_NUMBERED_PAGES

    (1..total).to_a
  end
end
