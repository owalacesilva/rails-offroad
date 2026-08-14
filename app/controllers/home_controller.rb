class HomeController < ApplicationController
  # MOCK: dados estáticos apenas para a vitrine da home.
  # Substituir por Category.all / Listing.recent quando os models existirem.
  #
  # Categorias e badges guardam só o slug: o texto exibido vive em config/locales,
  # porque é taxonomia fixa. Já título e localização dos anúncios são conteúdo do
  # usuário — não se traduzem e por isso ficam literais aqui.
  CATEGORIES = [
    { slug: "veiculos-4x4",      icon: :truck,  count: 1284 },
    { slug: "motos-quadriciclos", icon: :bike,   count: 862 },
    { slug: "pecas-acessorios",  icon: :wrench, count: 3517 }
  ].freeze

  RECENT_LISTINGS = [
    {
      title: "Jeep Wrangler Rubicon 3.6 V6",
      year: 2019,
      price: 389_900,
      location: "Curitiba, PR",
      category: "veiculos-4x4",
      badge: :prepared
    },
    {
      title: "Honda XR 300 Tornado",
      year: 2021,
      price: 24_500,
      location: "Belo Horizonte, MG",
      category: "motos-quadriciclos",
      badge: nil
    },
    {
      title: "Can-Am Maverick X3 Turbo RR",
      year: 2023,
      price: 415_000,
      location: "Campinas, SP",
      category: "utvs",
      badge: :featured
    },
    {
      title: "Kit Suspensão Old Man Emu +2\"",
      year: 2024,
      price: 8_790,
      location: "Porto Alegre, RS",
      category: "pecas-acessorios",
      badge: :new
    }
  ].freeze

  def index
    @categories = CATEGORIES
    @listings = RECENT_LISTINGS
  end
end
