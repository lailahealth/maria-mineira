require "net/http"
require "json"

module Classification
  # Camada 2 de classificação (seções 6.3/7 do parecer técnico): fallback de baixa
  # frequência via Anthropic Claude Haiku, chamado pelo Classification::Classifier
  # só quando a camada 1 (RuleBasedClassifier — grátis, local) não teve confiança
  # suficiente. Restrito à taxonomia já cadastrada e ativa: o modelo escolhe entre
  # as categorias existentes ou "nenhuma", nunca inventa uma tag nova — a taxonomia
  # é definida pela equipe, não por IA (seção 7 do PDF original).
  #
  # Minimização de dados: só o texto livre da usuária é enviado, sem session_id,
  # município ou qualquer outro identificador (seções 14/24 do PDF original).
  #
  # Sem chave de API configurada, #classify sempre retorna nil e o chamador usa
  # o resultado (de baixa confiança) da camada 1 — nunca quebra a conversa por
  # falta de orçamento/provedor de IA (pendência explícita do parecer, seção 9).
  #
  # Chamada síncrona, não um job (diferente do GeocodeFacilityJob): a resposta é
  # necessária para responder à mensagem atual do chat, e Haiku é rápido o
  # suficiente para não comprometer a UX na maioria dos casos (só entra quando a
  # camada 1 já não resolveu). Se a latência virar problema em produção, mover
  # para ClassifyMotiveJob + Turbo Stream assíncrono é o caminho (seção 5 do parecer).
  class LlmClassifier
    ENDPOINT = URI("https://api.anthropic.com/v1/messages")
    MODEL = "claude-haiku-4-5-20251001"
    API_VERSION = "2023-06-01"
    NONE = "nenhuma"

    def self.configured?
      api_key.present?
    end

    def self.api_key
      ENV["ANTHROPIC_API_KEY"].presence || Rails.application.credentials.dig(:anthropic, :api_key)
    end

    def self.classify(text)
      new.classify(text)
    end

    def classify(text)
      return nil unless self.class.configured?
      return nil if text.blank?

      catalog = classifiable_tags
      return nil if catalog.empty?

      slug = request_slug(text, catalog)
      return nil if slug.blank? || slug == NONE

      tag = catalog.find { |t| t.slug == slug }
      return nil unless tag

      tag_slug, subtag_slug = tag.origin_pair
      RuleBasedClassifier::Result.new(tag_slug: tag_slug, subtag_slug: subtag_slug, confidence: 0.5)
    rescue StandardError => e
      Rails.logger.warn("[Classification::LlmClassifier] falhou: #{e.class} #{e.message}")
      nil
    end

    private

    def classifiable_tags
      Taxonomy::Tag.active.includes(:parent).order(:kind, :position, :label).to_a
    end

    def request_slug(text, catalog)
      response = post(build_body(text, catalog))
      return nil unless response.is_a?(Net::HTTPSuccess)

      content = JSON.parse(response.body)["content"]
      text_block = content&.find { |block| block["type"] == "text" }
      text_block&.fetch("text", nil).to_s.strip.downcase
    end

    def post(body)
      request = Net::HTTP::Post.new(ENDPOINT)
      request["x-api-key"] = self.class.api_key
      request["anthropic-version"] = API_VERSION
      request["content-type"] = "application/json"
      request.body = body.to_json

      Net::HTTP.start(ENDPOINT.host, ENDPOINT.port, use_ssl: true, open_timeout: 5, read_timeout: 10) do |http|
        http.request(request)
      end
    end

    def build_body(text, catalog)
      {
        model: MODEL,
        max_tokens: 12,
        temperature: 0,
        system: [ { type: "text", text: system_prompt(catalog), cache_control: { type: "ephemeral" } } ],
        messages: [ { role: "user", content: text } ]
      }
    end

    def system_prompt(catalog)
      options = catalog.map { |tag| "- #{tag.slug}: #{tag.label}" }.join("\n")

      <<~PROMPT
        Você classifica mensagens curtas escritas por mulheres buscando informação e orientação na
        Maria Mineira, uma plataforma de Minas Gerais. Dada a mensagem da usuária, escolha a categoria
        que melhor descreve o assunto principal, entre as opções abaixo.

        Responda APENAS com o slug exato de uma categoria, em minúsculas, sem explicação e sem pontuação.
        Se nenhuma categoria descrever bem o assunto, responda exatamente: #{NONE}
        Nunca invente uma categoria que não esteja na lista.

        Categorias disponíveis:
        #{options}
      PROMPT
    end
  end
end
