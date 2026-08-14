class HomeController < ApplicationController
  # MOCK: dados estáticos apenas para a vitrine da home.
  # Substituir por Category.all / Listing.recent quando os models existirem.
  CATEGORIES = [
    {
      slug: "veiculos-4x4",
      icon: :truck,
      name: "Veículos 4x4",
      description: "Jipes, picapes e utilitários prontos para a trilha.",
      count: 1284
    },
    {
      slug: "motos-quadriciclos",
      icon: :bike,
      name: "Motos e Quadriciclos",
      description: "Trail, enduro, quadriciclos e UTVs de todas as cilindradas.",
      count: 862
    },
    {
      slug: "pecas-acessorios",
      icon: :wrench,
      name: "Peças & Acessórios",
      description: "Suspensão, pneus, guinchos, snorkel e preparação.",
      count: 3517
    }
  ].freeze

  RECENT_LISTINGS = [
    {
      title: "Jeep Wrangler Rubicon 3.6 V6",
      year: 2019,
      price: 389_900,
      location: "Curitiba, PR",
      category: "Veículos 4x4",
      badge: "Preparado"
    },
    {
      title: "Honda XR 300 Tornado",
      year: 2021,
      price: 24_500,
      location: "Belo Horizonte, MG",
      category: "Motos e Quadriciclos",
      badge: nil
    },
    {
      title: "Can-Am Maverick X3 Turbo RR",
      year: 2023,
      price: 415_000,
      location: "Campinas, SP",
      category: "UTVs",
      badge: "Destaque"
    },
    {
      title: "Kit Suspensão Old Man Emu +2\"",
      year: 2024,
      price: 8_790,
      location: "Porto Alegre, RS",
      category: "Peças & Acessórios",
      badge: "Novo"
    }
  ].freeze

  def index
    @categories = CATEGORIES
    @listings = RECENT_LISTINGS
  end
end
