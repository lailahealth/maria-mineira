# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
# Carregado direto do jsdelivr (não vendorizado): o bundle ESM da lib usa um Web
# Worker referenciado por URL absoluta relativa à própria origem do arquivo — só
# resolve corretamente quando servido do domínio do jsdelivr. CSS continua
# self-hosted normalmente (sem essa limitação).
pin "maplibre-gl", to: "https://cdn.jsdelivr.net/npm/maplibre-gl@6.3.0/+esm"
