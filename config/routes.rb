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
  get "converse", to: "pages#chat", as: :chat
  get "encontre-um-servico", to: "pages#service_search", as: :service_search
  get "mapa", to: "pages#map", as: :map_page
  get "tipos-de-violencia", to: "pages#violence_types", as: :violence_types
  get "direitos", to: "pages#rights", as: :rights
  get "politicas-e-programas", to: "pages#policies", as: :policies
  get "rede-maria-mineira", to: "pages#partners", as: :partners
  get "sobre", to: "pages#about", as: :about
end
