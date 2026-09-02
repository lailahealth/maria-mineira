module Classification
  # Camada 1 de classificação (seção 7 do parecer técnico): dicionário de palavras-chave
  # por subtag, determinístico e gratuito — nenhum texto sai da infraestrutura própria.
  # As palavras-chave são um rascunho e devem ser revisadas pela equipe Maria Mineira
  # junto com a taxonomia definitiva; não substituem avaliação humana.
  #
  # Quando a confiança for baixa, o chamador pode optar por uma camada 2 (LLM) — ainda
  # não conectada nesta fase (ver pendências do parecer sobre orçamento/provedor de IA).
  class RuleBasedClassifier
    Result = Struct.new(:tag_slug, :subtag_slug, :confidence, keyword_init: true) do
      def classified?
        subtag_slug.present?
      end
    end

    KEYWORDS_BY_SUBTAG = {
      "violencia_fisica" => %w[bateu apanhei agrediu agressão agressao soco chute machucou hematoma empurrou],
      "violencia_psicologica" => %w[ameaça ameaca humilha xinga controla ciúme ciume grita insulta medo constante],
      "violencia_sexual" => [
        "estupro", "abuso", "forçou", "forcou", "assédio", "assedio", "sexual", "contra minha vontade"
      ],
      "violencia_patrimonial" => [
        "dinheiro", "salário", "salario", "conta", "bens", "documentos",
        "não deixa trabalhar", "nao deixa trabalhar", "controla o dinheiro"
      ],
      "violencia_moral" => %w[calúnia calunia difama mentiras espalhou reputação reputacao]
    }.freeze

    KEYWORDS_BY_TAG = {
      "direitos" => [ "direito", "direitos", "lei maria da penha", "pensão", "pensao", "guarda", "filhos" ],
      "saude" => %w[saúde saude psicológico psicologico terapia atendimento médico medico],
      "autonomia_economica" => %w[trabalho emprego renda microcrédito microcredito independência financeira independencia financeira],
      "servicos_e_equipamentos" => %w[delegacia abrigo cras creas atendimento perto serviço servico]
    }.freeze

    def self.classify(text)
      new.classify(text)
    end

    def classify(text)
      normalized = normalize(text)
      return Result.new(confidence: 0.0) if normalized.blank?

      subtag_slug, subtag_score = best_match(normalized, KEYWORDS_BY_SUBTAG)
      if subtag_slug
        tag = Taxonomy::Tag.find_by(slug: subtag_slug)&.parent&.slug
        return Result.new(tag_slug: tag, subtag_slug: subtag_slug, confidence: confidence_for(subtag_score))
      end

      tag_slug, tag_score = best_match(normalized, KEYWORDS_BY_TAG)
      return Result.new(tag_slug: tag_slug, subtag_slug: nil, confidence: confidence_for(tag_score)) if tag_slug

      Result.new(confidence: 0.0)
    end

    private

    def best_match(normalized_text, dictionary)
      scores = dictionary.transform_values { |words| words.count { |w| normalized_text.include?(normalize(w)) } }
      best_key, best_score = scores.max_by { |_, score| score }
      return [ nil, 0 ] if best_score.to_i.zero?

      [ best_key, best_score ]
    end

    def confidence_for(score)
      [ score / 3.0, 1.0 ].min
    end

    def normalize(text)
      text.to_s.downcase.unicode_normalize(:nfkd).gsub(/[^\x00-\x7F]/, "").strip
    end
  end
end
