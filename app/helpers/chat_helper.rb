module ChatHelper
  # Link "Como chegar" no estilo Google Maps (seção 8 do parecer técnico: a usuária
  # precisa conseguir agir sobre o resultado, não só lê-lo). Usa as coordenadas quando
  # o equipamento já foi geocodificado — rota ponto a ponto, como no app do Google —
  # e cai no endereço em texto livre quando ainda não há latitude/longitude.
  def facility_directions_url(facility)
    destination =
      if facility.latitude.present? && facility.longitude.present?
        "#{facility.latitude},#{facility.longitude}"
      else
        [ facility.address, facility.neighborhood, facility.municipality.name, "MG", "Brasil" ]
          .select(&:present?).join(", ")
      end

    "https://www.google.com/maps/dir/?api=1&destination=#{CGI.escape(destination)}"
  end

  # href para discagem direta no celular — só os dígitos, sem máscara.
  def tel_href(phone)
    "tel:#{phone.to_s.gsub(/\D/, '')}"
  end

  # Explicação em linguagem simples do que cada tipo de equipamento faz. O card do
  # chat mostra a sigla (DEAM, CRAS, CREAS, CREAM/CRAM…) e nem toda mulher sabe o
  # que significam — sem isso o resultado não orienta de fato (seção 8 do parecer).
  # Casa tanto pelo facility_type livre quanto pelas categorias de serviço
  # vinculadas. A redação deve ser revista pela equipe Maria Mineira, junto com a
  # taxonomia definitiva.
  def facility_type_explanation(facility)
    haystack = ([ facility.facility_type ] + facility.service_categories.map(&:slug))
      .compact.join(" ").downcase.unicode_normalize(:nfkd).gsub(/[^\x00-\x7F ]/, "")

    case haystack
    when /deam|delegacia/
      "Delegacia com equipe preparada para atender mulheres em situação de violência. É onde você pode " \
        "registrar o boletim de ocorrência e pedir medida protetiva contra o agressor."
    when /cream|cram|casa da mulher|centro de referencia de atendimento a mulher/
      "Centro que atende só mulheres, de graça e sem precisar registrar denúncia. Oferece acolhimento e " \
        "acompanhamento com psicóloga, assistente social e orientação sobre os seus direitos."
    when /creas/
      "Serviço da assistência social para quem teve direitos violados, inclusive por violência. Faz " \
        "acompanhamento com equipe técnica e articula com a Justiça e a rede de proteção."
    when /\bcras\b/
      "Porta de entrada da assistência social, no seu bairro. Ajuda com o Cadastro Único, benefícios como " \
        "o Bolsa Família e o BPC, e orientação para famílias."
    when /abrigo|acolhimento|casa de apoio|casa de passagem/
      "Acolhimento temporário e sigiloso para mulheres em risco de morte e seus filhos. O endereço não é " \
        "divulgado e o acesso costuma ser pela Justiça, pela delegacia ou por um centro de referência."
    when /clinica/
      "Serviço de saúde voltado para a mulher, com atendimento psicológico e acompanhamento de saúde " \
        "física e mental."
    when /conselho/
      "Órgão que acompanha as políticas públicas para as mulheres no município. Orienta e encaminha " \
        "demandas, mas não faz atendimento de urgência."
    when /central|180/
      "Central telefônica nacional, gratuita e 24 horas. Orienta sobre direitos e serviços e registra " \
        "denúncias de violência. É só ligar 180 de qualquer telefone."
    when /juridic/
      "Atendimento com profissional do Direito para explicar os seus direitos e orientar sobre pensão, " \
        "guarda, divórcio e medida protetiva — de graça."
    when /psicolog/
      "Acompanhamento com psicóloga para cuidar do impacto emocional da violência, em sigilo."
    end
  end
end
