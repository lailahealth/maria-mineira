module Territorial
  # Resolve município/CEP a partir de texto — usada tanto pelo campo dedicado de
  # localização (#resolve, tolerante: aceita nome parcial de município, porque ali
  # a intenção de informar uma localização já é explícita) quanto pela detecção
  # automática de localização dentro do texto livre do chat (#resolve_strict).
  #
  # #resolve_strict é deliberadamente rígida: só reconhece a mensagem inteira como
  # localização quando ela é só um CEP, bate exatamente com um nome de município, ou
  # tem 1-2 letras de diferença dele (erro de digitação — ver Municipality#fuzzy_match).
  # Nunca por "contém", para não confundir "tem muita formiga aqui" com um pedido
  # de busca por região.
  #
  # #extract vai um passo além, para quem escreve do jeito que fala ("Estou em Juiz
  # de Fora", "moro em Uberlândia, quais meus direitos?"): só procura a cidade logo
  # depois de um gatilho explícito de localização ("estou em", "moro em", "sou de",
  # "minha cidade é"…), testando as palavras seguintes do trecho mais longo para o
  # mais curto. Ainda nunca por "contém" solto — e "estou em casa" ou "sou de
  # confiança" não viram busca porque "casa"/"confiança" não são município.
  #
  # Gatilho negado não conta: "não moro em BH, moro numa cidade pequena" buscava
  # Belo Horizonte e mostrava os serviços de lá como "perto de você". Gatilhos mais
  # soltos ("fica em", "é em", ou uma oração que é só ", em Itabira") só aceitam o
  # nome exato do município, sem tolerância a erro de digitação.
  module LocationResolver
    CEP_ONLY = /\A\d{5}-?\d{3}\z/
    # CEP no meio de uma frase: com hífen, ou precedido de "cep" — 8 dígitos soltos
    # poderiam ser um telefone fixo.
    CEP_IN_TEXT = /(?:\bcep\D{0,5}(\d{5}-?\d{3})|\b(\d{5}-\d{3}))\b/
    # Aplicados ao texto já normalizado (minúsculo, sem acento).
    LOCATION_TRIGGER = /\b(?:estou|esto|to|tou|estamos|moro|mora|moram|moramos|morava|moravamos|morei|moradora|morador|vivo|vive|vivemos|vivia|resido|reside|fico|sou|somos|aqui|cidade|municipio|cidade e|municipio e)\s+(?:em|no|na|de|do|da|e)\s+/
    LOOSE_TRIGGER = /\b(?:fica|ficam|ficamos|e)\s+(?:em|no|na|de|do|da)\s+/
    # Oração que é só a cidade, com palavras de enchimento antes: "…, em Itabira",
    # "na verdade é Itabira", "é em Itabira".
    CLAUSE_FILLER = /\A(?:(?:mas|na verdade|e|em|no|na|so|sim|ok|entao)\s+)+/
    NEGATION = /\b(?:nao|nem|nunca)\s+(?:\S+\s+)?\z/
    STATE_SUFFIX = /[\s,\-\/]*\b(?:mg|minas gerais|minas)\s*[.!?]*\s*\z/i
    MAX_NAME_WORDS = 6
    ALIASES = { "bh" => "belo horizonte", "jf" => "juiz de fora" }.freeze

    def self.resolve(query)
      return {} if query.blank?

      digits = query.to_s.gsub(/\D/, "")
      return resolve_cep(digits) if digits.length == 8

      municipality = Territorial::Municipality.search_by_name(query)
      return { municipality: municipality } if municipality

      extract(query).except(:remainder)
    end

    # Localização escrita em qualquer forma natural. Além de municipality/lat/lng,
    # devolve :remainder — o resto da mensagem sem a parte da localização (texto
    # normalizado), para Chat::TurnHandler decidir se ainda há uma pergunta a
    # responder além de buscar os serviços.
    def self.extract(text)
      strict = resolve_strict(text.to_s.sub(STATE_SUFFIX, ""))
      return strict.merge(remainder: "") if strict.present?

      if (cep = text.to_s.downcase.match(CEP_IN_TEXT))
        found = resolve_cep((cep[1] || cep[2]).gsub(/\D/, ""))
        return found.merge(remainder: Territorial::Municipality.normalize(text.to_s.sub(/#{Regexp.escape(cep[0])}/i, " "))) if found.present?
      end

      normalized = Territorial::Municipality.normalize(text)
      after_trigger(normalized, LOCATION_TRIGGER, fuzzy: true) ||
        after_trigger(normalized, LOOSE_TRIGGER, fuzzy: false) ||
        clause_with_only_the_city(normalized) ||
        {}
    end

    def self.resolve_strict(text)
      trimmed = text.to_s.strip
      return {} if trimmed.blank?

      return resolve_cep(trimmed.gsub(/\D/, "")) if CEP_ONLY.match?(trimmed)

      municipality = Territorial::Municipality.exact_match(trimmed) || Territorial::Municipality.fuzzy_match(trimmed)
      municipality ? { municipality: municipality } : {}
    end

    def self.resolve_cep(digits)
      return {} unless digits.length == 8

      result = Territorial::CepLookup.lookup(digits)
      return {} unless result

      municipality = Territorial::Municipality.find_by(ibge_code: result.ibge_code)
      address_query = [ result.street, result.neighborhood, result.city, result.state, "Brasil" ].select(&:present?).join(", ")
      geocoded = Territorial::Geocoder.geocode(address_query)

      geocoded ? { lat: geocoded.latitude, lng: geocoded.longitude, municipality: municipality } : { municipality: municipality }
    end

    def self.after_trigger(normalized, trigger, fuzzy:)
      normalized.to_enum(:scan, trigger).each do
        match = Regexp.last_match
        next if NEGATION.match?(normalized[0...match.begin(0)])

        found = municipality_at_start_of(normalized[match.end(0)..], fuzzy: fuzzy)
        next unless found

        municipality, consumed = found
        # Gatilho solto só vale se a cidade fecha a oração: "é de Luz" sim,
        # "ele é de luz apagada" não.
        next if !fuzzy && !normalized[(match.end(0) + consumed)..].match?(/\A\s*(?:[,;.!?]|\z|(?:mg|minas)\b)/)
        remainder = normalized[0...match.begin(0)] + " " + normalized[(match.end(0) + consumed)..]
        return { municipality: municipality, remainder: remainder.sub(STATE_SUFFIX, "").squish }
      end

      nil
    end

    def self.clause_with_only_the_city(normalized)
      clauses = normalized.split(/[,;.!?]/)
      clauses.each_with_index do |clause, index|
        candidate = clause.sub(STATE_SUFFIX, "").strip.sub(CLAUSE_FILLER, "")
        municipality = Territorial::Municipality.exact_match(ALIASES.fetch(candidate, candidate))
        next unless municipality

        remainder = (clauses[0...index] + clauses[(index + 1)..]).join(" ")
        return { municipality: municipality, remainder: remainder.squish }
      end

      nil
    end

    # Testa as primeiras palavras depois do gatilho, da janela mais longa para a
    # mais curta ("juiz de fora e ele" → "juiz de fora e" → "juiz de fora" ✓), para
    # casar nomes compostos sem engolir o resto da frase. Todas as janelas passam
    # pela igualdade exata antes da tolerância a erro de digitação — senão
    # "juiz de fora e" (2 letras a mais) casaria antes de "juiz de fora".
    # Devolve o município e quantos caracteres do trecho ele ocupou.
    def self.municipality_at_start_of(fragment, fuzzy:)
      words = fragment.to_s.scan(/[a-z0-9']+/).first(MAX_NAME_WORDS)
      windows = words.length.downto(1).map { |size| [ size, ALIASES.fetch(words.first(size).join(" ")) { |name| name } ] }

      (fuzzy ? %i[exact_match fuzzy_match] : %i[exact_match]).each do |matcher|
        windows.each do |size, candidate|
          municipality = Territorial::Municipality.public_send(matcher, candidate)
          next unless municipality

          consumed = fragment.match(/\A[^a-z0-9']*#{words.first(size).map { |word| Regexp.escape(word) }.join("[^a-z0-9']+")}/)[0].length
          return [ municipality, consumed ]
        end
      end

      nil
    end
    private_class_method :resolve_cep, :after_trigger, :clause_with_only_the_city, :municipality_at_start_of
  end
end
