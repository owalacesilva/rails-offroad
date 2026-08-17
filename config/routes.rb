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

  # Páginas institucionais. Uma controller só (PagesController) porque não há
  # estado nenhum: cada action escolhe um template e o texto vem dos locales.
  get "sobre-nos",               to: "pages#about",            as: :about
  get "como-anunciar",           to: "pages#how_to_advertise", as: :how_to_advertise
  get "politica-de-privacidade", to: "pages#privacy",          as: :privacy_policy
  get "termos-de-uso",           to: "pages#terms",            as: :terms_of_use

  # Inscrição na newsletter, enviada pelo bloco da home. Só POST: não há
  # página própria para listar nem editar inscrição.
  post "newsletter", to: "newsletter_subscriptions#create", as: :newsletter_subscription

  # Painel do anunciante autenticado, todo sob /anunciante. Os helpers seguem
  # account_* — a rota é portuguesa, o código é inglês.
  scope module: "dashboard", path: "anunciante" do
    get   "",              to: "dashboard#index", as: :account
    get   "anuncios",      to: "ads#index",       as: :account_ads
    get   "anuncios/novo", to: "ads#new",         as: :new_account_ad
    # as: nil porque o POST divide o caminho com o GET acima: sem isso o Rails
    # inventaria o helper `anuncios_path` a partir do segmento em português.
    post  "anuncios",      to: "ads#create",      as: nil
    get   "perfil",        to: "profiles#edit",   as: :edit_profile
    patch "perfil",        to: "profiles#update", as: :profile
    get   "propostas",     to: "proposals#index", as: :proposals
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
