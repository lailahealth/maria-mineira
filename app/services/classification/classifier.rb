module Classification
  # Ponto único de entrada para classificar texto livre (seção 7 do parecer
  # técnico): tenta a camada 1 (RuleBasedClassifier) primeiro, e só recorre à
  # camada 2 (LlmClassifier) quando a confiança da camada 1 for baixa — mantendo
  # o custo e a exposição de texto a terceiros mínimos, como documentado na
  # seção 7 do parecer ("opção mais barata recomendada").
  class Classifier
    # RuleBasedClassifier#confidence_for é score/3.0 — 1 palavra-chave já dá 0.33.
    # O limiar fica abaixo disso de propósito: qualquer palavra-chave encontrada é
    # aceita como resposta da camada 1 (grátis), e só a ausência total de sinal
    # (confiança 0.0) aciona a camada 2. Um limiar mais alto faria a LLM ser
    # chamada na maioria das mensagens curtas, o oposto do "regras resolvem a
    # maioria dos casos" da seção 7 do parecer técnico.
    LOW_CONFIDENCE_THRESHOLD = 0.3

    def self.classify(text)
      new.classify(text)
    end

    def classify(text)
      result = RuleBasedClassifier.classify(text)
      return result if result.confidence >= LOW_CONFIDENCE_THRESHOLD

      LlmClassifier.classify(text) || result
    end
  end
end
