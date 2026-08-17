class HomeController < ApplicationController
  allow_unauthenticated_access

  # Seis por fileira, duas fileiras — os doze recentes que a home mostra. Só a
  # fileira vira constante e o total é derivado dela: assim não existe o estado
  # em que se pedem treze anúncios e a segunda fileira fica torta. Seis é o que
  # cabe na régua de cards em tela larga.
  RECENT_ROW = 6

  MOST_VIEWED_LIMIT = 12

  EVENTS_LIMIT = 4

  # Fotos por galeria. São duas na página — uma logo abaixo dos recentes e outra
  # fechando —, e a de baixo continua de onde a de cima parou.
  GALLERY_SIZE = 12

  # Atalhos de busca do hero, em dois grupos como a vitrine sugere: primeiro o
  # que se compra inteiro, depois o que se compra para montar. São nomes de
  # modelo e de peça — nome próprio, por isso constante e não chave de tradução.
  QUICK_SEARCHES = {
    vehicles: %w[Defender Wrangler Hilux Ranger Troller Jimny Bandeirante Frontier].freeze,
    parts: %w[Snorkel Guincho Suspensão Bloqueio Bagageiro Pneus].freeze
  }.freeze

  def index
    published = Ad.published.with_photos.includes(:category)
    photos = gallery_photos

    @ads = published.recent.limit(RECENT_ROW * 2)
    @most_viewed = published.most_viewed.limit(MOST_VIEWED_LIMIT)
    @events = Event.upcoming.limit(EVENTS_LIMIT)
    @gallery_top = photos.first(GALLERY_SIZE)
    @gallery_bottom = photos.drop(GALLERY_SIZE)
  end

  private
    # Uma consulta só para as duas galerias, fatiada depois: buscar duas vezes
    # com OFFSET repetiria o mesmo trabalho e não garantiria que a segunda
    # galeria não repetisse foto da primeira.
    #
    # A ordem mantém juntas as fotos de um mesmo anúncio, que é o que faz o
    # mosaico parecer galeria e não uma segunda régua de capas.
    def gallery_photos
      AdImage.with_attached_file
             .joins(:ad)
             .merge(Ad.published)
             .includes(:ad)
             .order("ads.published_at DESC", :ad_id, :sort_order)
             .limit(GALLERY_SIZE * 2)
             .to_a
    end
end
