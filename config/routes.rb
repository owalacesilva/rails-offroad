Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Autenticação: sessão em tabela com o id em cookie assinado.
  get    "entrar",    to: "sessions#new", as: :login
  post   "entrar",    to: "sessions#create"
  delete "sair",      to: "sessions#destroy", as: :logout
  get    "cadastrar", to: "registrations#new", as: :signup
  post   "cadastrar", to: "registrations#create"

  # Vitrine de anúncios com filtros. Rota em português, código em inglês.
  resources :listings, only: %i[index show], path: "anuncios" do
    resources :proposals, only: :create, path: "propostas"
  end

  # Painel do anunciante autenticado.
  get "minha-conta", to: "dashboard#index", as: :account

  # Defines the root path route ("/")
  root "home#index"
end
