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

  # Acima disso a régua numerada fica ilegível e sobra só anterior/próxima.
  MAX_NUMBERED_PAGES = 9

  def paginated_page_numbers(pagination)
    total = pagination.total_pages
    return [] if total > MAX_NUMBERED_PAGES

    (1..total).to_a
  end
end
