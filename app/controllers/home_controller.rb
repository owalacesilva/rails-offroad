class HomeController < ApplicationController
  allow_unauthenticated_access

  # Seis por fileira, duas fileiras — os doze recentes que a home mostra. Só a
  # fileira vira constante e o total é derivado dela: assim não existe o estado
  # em que se pedem treze anúncios e a segunda fileira fica torta. Seis é o que
  # cabe na régua de cards em tela larga.
  RECENT_ROW = 6

  MOST_VIEWED_LIMIT = 12

  EVENTS_LIMIT = 4

  # Três cabem numa fileira e é o quanto de blog a home comporta sem virar
  # outra página. O resto está em /blog.
  POSTS_LIMIT = 3

  # Fotos por galeria. São duas na página — uma logo abaixo dos recentes e outra
  # fechando —, e a de baixo continua de onde a de cima parou.
  GALLERY_SIZE = 12

  def index
    published = Ad.published.with_photos.includes(:category)

    @ads = published.recent.limit(RECENT_ROW * 2)
    @most_viewed = published.most_viewed.limit(MOST_VIEWED_LIMIT)
    @event_banner = Event.banner
    @events = Event.upcoming.limit(EVENTS_LIMIT)
    @posts = Post.published.includes(:admin).limit(POSTS_LIMIT)
    # As duas galerias saem juntas de uma consulta só (ver gallery_pages).
    @gallery_top, @gallery_bottom = gallery_pages
  end

  private
    # Uma consulta só para as duas galerias, já fatiada nas duas metades: a de
    # baixo continua de onde a de cima parou, sem repetir foto e sem um segundo
    # OFFSET que refaria o mesmo trabalho.
    #
    # A ordem mantém juntas as fotos de um mesmo anúncio, que é o que faz o
    # mosaico parecer galeria e não uma segunda régua de capas.
    #
    # values_at + to_a no fim: com menos de GALLERY_SIZE fotos o segundo pedaço
    # não existe, e o partial espera lista vazia, não nil.
    def gallery_pages
      AdImage.visible
             .with_attached_file
             .joins(:ad)
             .merge(Ad.published)
             .includes(:ad)
             .order("ads.published_at DESC", :ad_id, :sort_order)
             .limit(GALLERY_SIZE * 2)
             .each_slice(GALLERY_SIZE)
             .first(2)
             .values_at(0, 1)
             .map(&:to_a)
    end
end
