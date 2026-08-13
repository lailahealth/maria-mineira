Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "home#index"

  # Menu principal (seção 25 do parecer técnico). Cada rota aponta, por enquanto, para uma
  # tela "em construção" — mantém a navegação completa e clicável desde a fundação, sem
  # simular funcionalidades que ainda não foram implementadas.
  get "converse", to: "chat/conversations#show", as: :chat
  post "converse/mensagens", to: "chat/messages#create", as: :chat_messages

  # "Encontrar um serviço" agora acontece dentro da própria conversa (Entrada 2 —
  # ver seção 1 do parecer técnico), não numa tela de busca separada.
  get "encontre-um-servico", to: redirect("/converse"), as: :service_search
  get "mapa", to: "map#index", as: :map_page
  get "mapa/municipios/:id", to: "territorial/municipalities#show", as: :territorial_municipality
  get "mapa/equipamentos/:id", to: "territorial/facilities#show", as: :territorial_facility

  # Conteúdo educativo (seções 18-19 do PDF original). Navegar por essas páginas
  # é a Entrada 1 (origem por conteúdo, passiva) — ver ApplicationController#record_content_origin.
  get "tipos-de-violencia", to: "content/violence_types#index", as: :violence_types
  get "tipos-de-violencia/:id", to: "content/violence_types#show", as: :violence_type

  get "direitos", to: "content/pages#index", defaults: { section: "direitos" }, as: :rights
  get "direitos/:id", to: "content/pages#show", defaults: { section: "direitos" }, as: :right

  get "politicas-e-programas", to: "content/pages#index", defaults: { section: "politicas-e-programas" }, as: :policies
  get "politicas-e-programas/:id", to: "content/pages#show", defaults: { section: "politicas-e-programas" }, as: :policy

  get "rede-maria-mineira", to: "partners/partners#index", as: :partners
  get "sobre", to: "pages#about", as: :about

  # CMS interno (seção 3.7 do parecer técnico). Autenticação nativa do Rails 8,
  # escopada só aqui — a usuária final nunca loga (ver ApplicationController).
  namespace :admin do
    resource :session
    resources :passwords, param: :token

    root "dashboard#index"
    resources :pages
    resources :tags
    resources :facilities
    resources :service_categories
    resources :municipalities, only: %i[index show]
    resources :partners
    resources :users
  end
end
