class HomeController < ApplicationController
  allow_unauthenticated_access

  # Seis cabem na régua de cards da vitrine em telas largas.
  RECENT_LIMIT = 6

  # Atalhos de busca do hero, em dois grupos como a vitrine sugere: primeiro o
  # que se compra inteiro, depois o que se compra para montar. São nomes de
  # modelo e de peça — nome próprio, por isso constante e não chave de tradução.
  QUICK_SEARCHES = {
    vehicles: %w[Defender Wrangler Hilux Ranger Troller Jimny Bandeirante Frontier].freeze,
    parts: %w[Snorkel Guincho Suspensão Bloqueio Bagageiro Pneus].freeze
  }.freeze

  def index
    published = Ad.published

    @categories = Category.ordered
    # Uma consulta agregada em vez de category.ads.count por card.
    @ad_counts = published.group(:category_id).count
    @ads = published.includes(:category, :ad_images).recent.limit(RECENT_LIMIT)
  end
end
