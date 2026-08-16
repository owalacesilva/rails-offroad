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
  resources :ads, only: %i[index show], path: "anuncios" do
    resources :proposals, only: :create, path: "propostas"
  end

  # Painel do anunciante autenticado.
  scope module: "dashboard" do
    get   "minha-conta",           to: "dashboard#index",  as: :account
    get   "minha-conta/anuncios",  to: "ads#index",        as: :account_ads
    get   "minha-conta/perfil",    to: "profiles#edit",    as: :edit_profile
    patch "minha-conta/perfil",    to: "profiles#update",  as: :profile
    get   "minha-conta/propostas", to: "proposals#index",  as: :proposals
  end

  # Moderação. Sessão própria, separada da do anunciante. O módulo é Moderation
  # porque Admin já é o modelo; as URLs e os helpers seguem sendo /admin e admin_*.
  namespace :admin, module: "moderation" do
    get    "entrar", to: "sessions#new",     as: :login
    post   "entrar", to: "sessions#create"
    delete "sair",   to: "sessions#destroy", as: :logout

    resources :ads, only: :index, path: "anuncios" do
      member do
        patch :approve, path: "aprovar"
        patch :reject,  path: "rejeitar"
      end
    end

    root "ads#index"
  end

  # Defines the root path route ("/")
  root "home#index"
end
