require "net/http"
require "json"

# ---------------------------------------------------------------------------
# Taxonomia (rascunho inicial — NÃO é a taxonomia definitiva).
# A equipe Maria Mineira administra a versão real (seções 5-7 do parecer técnico).
# Os 5 tipos de violência seguem a nomenclatura do art. 7º da Lei Maria da Penha.
# ---------------------------------------------------------------------------
puts "Semeando taxonomia (rascunho)..."

root_tags = {
  "violencia_contra_mulher" => "Violência contra a mulher",
  "direitos" => "Direitos",
  "saude" => "Saúde",
  "autonomia_economica" => "Autonomia econômica",
  "trabalho_e_renda" => "Trabalho e renda",
  "politicas_publicas" => "Políticas públicas",
  "servicos_e_equipamentos" => "Serviços e equipamentos",
  "programas" => "Programas",
  "participacao" => "Participação",
  "campanhas" => "Campanhas"
}

root_tags.each do |slug, label|
  Taxonomy::Tag.find_or_create_by!(slug: slug) { |t| t.label = label; t.kind = :general }
end

violencia = Taxonomy::Tag.find_by!(slug: "violencia_contra_mulher")

violence_types = {
  "violencia_fisica" => "Violência física",
  "violencia_psicologica" => "Violência psicológica",
  "violencia_sexual" => "Violência sexual",
  "violencia_patrimonial" => "Violência patrimonial",
  "violencia_moral" => "Violência moral"
}

violence_types.each do |slug, label|
  Taxonomy::Tag.find_or_create_by!(slug: slug) { |t| t.label = label; t.kind = :violence_type; t.parent = violencia }
end

# ---------------------------------------------------------------------------
# Categorias de serviço — vocabulário público já consolidado no Brasil (DEAM, CRAS,
# CREAS, Central 180 etc.), usado para ligar tag_motivo a tipos de equipamento.
# ---------------------------------------------------------------------------
puts "Semeando categorias de serviço..."

servicos_tag = Taxonomy::Tag.find_by!(slug: "servicos_e_equipamentos")
saude_tag = Taxonomy::Tag.find_by!(slug: "saude")
direitos_tag = Taxonomy::Tag.find_by!(slug: "direitos")

service_categories = [
  { slug: "deam", name: "Delegacia Especializada de Atendimento à Mulher (DEAM)", tag: servicos_tag },
  { slug: "casa-de-abrigo", name: "Casa de Abrigo", tag: servicos_tag },
  { slug: "cras", name: "Centro de Referência de Assistência Social (CRAS)", tag: servicos_tag },
  { slug: "creas", name: "Centro de Referência Especializado de Assistência Social (CREAS)", tag: servicos_tag },
  { slug: "central-180", name: "Central de Atendimento à Mulher (180)", tag: servicos_tag },
  { slug: "cream-cram", name: "Centro de Referência de Atendimento à Mulher (CREAM/CRAM)", tag: servicos_tag },
  { slug: "atendimento-psicologico", name: "Atendimento psicológico", tag: saude_tag },
  { slug: "orientacao-juridica", name: "Orientação jurídica", tag: direitos_tag }
]

service_categories.each do |attrs|
  Territorial::ServiceCategory.find_or_create_by!(slug: attrs[:slug]) do |sc|
    sc.name = attrs[:name]
    sc.taxonomy_tag = attrs[:tag]
  end
end

# ---------------------------------------------------------------------------
# Municípios de Minas Gerais — fonte oficial gratuita (IBGE Localidades), seção 6.1
# do parecer técnico. Não inventar/hardcodar a lista: buscar dinamicamente.
# ---------------------------------------------------------------------------
puts "Semeando municípios de MG (API do IBGE)..."

begin
  uri = URI("https://servicodados.ibge.gov.br/api/v1/localidades/estados/MG/municipios")
  response = Net::HTTP.get_response(uri)

  if response.is_a?(Net::HTTPSuccess)
    municipios = JSON.parse(response.body)
    municipios.each do |m|
      Territorial::Municipality.find_or_create_by!(ibge_code: m["id"].to_s) do |muni|
        muni.name = m["nome"]
        muni.region = m.dig("microrregiao", "mesorregiao", "nome")
        muni.state = "MG"
      end
    end
    puts "  #{Territorial::Municipality.count} municípios carregados."
  else
    puts "  Aviso: IBGE respondeu #{response.code} — municípios não foram carregados. Rode `rails db:seed` novamente com internet disponível."
  end
rescue StandardError => e
  puts "  Aviso: não foi possível buscar municípios do IBGE agora (#{e.class}: #{e.message}). Rode `rails db:seed` novamente com internet disponível."
end

# ---------------------------------------------------------------------------
# Páginas de conteúdo (seções 18-19 do PDF original). IMPORTANTE: o PDF é explícito
# — "conceitos... serão fornecidos pela equipe. Não criar ou alterar definições."
# Por isso o corpo de cada página aqui é um placeholder claramente identificado como
# tal, não uma explicação educativa de fato — só a base legal (número da lei/artigo)
# é citada, sem reproduzir texto integral que não possa ser verificado agora.
# ---------------------------------------------------------------------------
puts "Semeando páginas de conteúdo (placeholder)..."

def placeholder_body(topic)
  <<~TEXT.strip
    Conteúdo pendente. A equipe Maria Mineira vai fornecer aqui o conceito oficial sobre #{topic}, incluindo explicação educativa, sinais de alerta e orientações — na linguagem e identidade da própria marca.

    Este protótipo não cria nem reinterpreta esse conteúdo. A referência legal de base é o art. 7º da Lei nº 11.340/2006 (Lei Maria da Penha), que define as formas de violência doméstica e familiar contra a mulher.
  TEXT
end

violence_type_pages = {
  "violencia_fisica" => "violência física",
  "violencia_psicologica" => "violência psicológica",
  "violencia_sexual" => "violência sexual",
  "violencia_patrimonial" => "violência patrimonial",
  "violencia_moral" => "violência moral"
}

violence_type_pages.each do |tag_slug, label|
  tag = Taxonomy::Tag.find_by!(slug: tag_slug)
  Content::Page.find_or_create_by!(slug: tag_slug) do |page|
    page.content_type = :tipo_violencia
    page.title = tag.label
    page.summary = "Conceito oficial pendente — conteúdo será fornecido pela equipe Maria Mineira."
    page.body = placeholder_body(label)
    page.taxonomy_tag = tag
    page.published_at = Time.current
  end
end

direitos_pages = [
  { slug: "medidas-protetivas", title: "Medidas protetivas de urgência", topic: "medidas protetivas de urgência" },
  { slug: "pensao-e-guarda", title: "Pensão alimentícia e guarda dos filhos", topic: "pensão alimentícia e guarda" }
]

direitos_pages.each do |attrs|
  Content::Page.find_or_create_by!(slug: attrs[:slug]) do |page|
    page.content_type = :direito
    page.title = attrs[:title]
    page.summary = "Conteúdo pendente — a equipe Maria Mineira vai detalhar este direito aqui."
    page.body = placeholder_body(attrs[:topic])
    page.taxonomy_tag = Taxonomy::Tag.find_by(slug: "direitos")
    page.published_at = Time.current
  end
end

politicas_pages = [
  { slug: "lei-maria-da-penha", title: "Lei Maria da Penha", content_type: :politica, topic: "a Lei Maria da Penha" },
  { slug: "casa-da-mulher-mineira", title: "Programa Casa da Mulher Mineira", content_type: :programa, topic: "o programa Casa da Mulher Mineira" }
]

politicas_pages.each do |attrs|
  Content::Page.find_or_create_by!(slug: attrs[:slug]) do |page|
    page.content_type = attrs[:content_type]
    page.title = attrs[:title]
    page.summary = "Conteúdo pendente — a equipe Maria Mineira vai detalhar esta política/programa aqui."
    page.body = placeholder_body(attrs[:topic])
    page.taxonomy_tag = Taxonomy::Tag.find_by(slug: "politicas_publicas")
    page.published_at = Time.current
  end
end

puts "  #{Content::Page.count} páginas de conteúdo."

# ---------------------------------------------------------------------------
# Equipamentos (Territorial::Facility): amostra de 5 serviços públicos REAIS de
# MG, pesquisados e conferidos (não são dados fictícios) — para validar a busca
# por proximidade de ponta a ponta. Não é a base completa "que a equipe vai
# fornecer" (PDF original); é uma amostra real, com fonte, para teste. Fora
# desta amostra, a busca continua caindo em "ainda não temos informações
# suficientes" normalmente (seção 11 do PDF). Coordenadas não são fixadas aqui:
# nascem sem lat/lng e o GeocodeFacilityJob preenche a partir do endereço.
# ---------------------------------------------------------------------------
puts "Semeando amostra de equipamentos reais..."

real_facilities = [
  {
    # https://www.sinjus.org.br/nm/deams.html
    name: "DEAM Belo Horizonte", facility_type: "DEAM", municipality: "Belo Horizonte",
    address: "Avenida Augusto de Lima, 1942", neighborhood: "Barro Preto", cep: "30190-002",
    phone: "(31) 3337-4899",
    opening_hours: "Segunda a sexta, 8h30 às 12h (DEPAM no mesmo endereço funciona 24h, todos os dias)",
    description: "Delegacia Especializada de Atendimento à Mulher de Belo Horizonte.",
    categories: %w[deam]
  },
  {
    # https://www.pjf.mg.gov.br/noticias/view.php?modo=link2&idnoticia2=69532
    name: "Casa da Mulher Maria da Conceição Lammoglia Jabour", facility_type: "Casa da Mulher",
    municipality: "Juiz de Fora", address: "Avenida Garibaldi Campinhos, 169", neighborhood: "Vitorino Braga",
    phone: "(32) 3690-7292", opening_hours: "Segunda a sexta, 8h às 17h",
    description: "Centro de referência municipal de Juiz de Fora para atendimento humanizado a mulheres em " \
      "situação de violência doméstica (assistência social e acompanhamento psicológico).",
    categories: %w[atendimento-psicologico]
  },
  {
    # https://www.acheiuberlandia.com/guiacomercial/delegacia-da-mulher/
    name: "DEAM Uberlândia", facility_type: "DEAM", municipality: "Uberlândia",
    address: "Rua Nicomedes Alves dos Santos, 727", neighborhood: "Lídice",
    phone: "(34) 3210-8304", opening_hours: "Segunda a sexta, 8h às 18h",
    description: "Delegacia Especializada de Atendimento à Mulher de Uberlândia.",
    categories: %w[deam]
  },
  {
    # https://agendamentocras.com.br/mg/contagem/cras-contagem-sede/
    name: "CRAS Sede Contagem", facility_type: "CRAS", municipality: "Contagem",
    address: "Rua Joaquim José, 128", neighborhood: "Fonte Grande",
    phone: "(31) 3352-5361",
    description: "Centro de Referência de Assistência Social sede de Contagem.",
    categories: %w[cras]
  },
  {
    # https://www.assistenciasocial.org/creas-betim-mg-endereco-e-atendimento/
    name: "CREAS I Betim", facility_type: "CREAS", municipality: "Betim",
    address: "Rua Carandaí, 87", neighborhood: "Chácara",
    phone: "(31) 3591-1581", opening_hours: "Segunda a sexta, 8h às 17h",
    description: "Centro de Referência Especializado de Assistência Social de Betim.",
    categories: %w[creas]
  },

  # A partir daqui: levantamento de políticas e equipamentos para mulheres em
  # municípios de MG (letras A-G), "docs/Análise dos links de politicas das
  # mulheres em MG - Municipios A até G.pdf". Endereço/telefone só quando o
  # levantamento os informa; sem eles, o equipamento é geocodificado no nível
  # do município (ver Territorial::Facility#geocoding_query) em vez de
  # inventar um logradouro.
  {
    # araguari.mg.gov.br/noticias/centro-de-apoio-municipal-a-mulher-vitima-de-violencia-domestica-e-uma-realidade-importante-para-araguari
    name: "Creas Mulher Araguari", facility_type: "CREAM/CRAM", municipality: "Araguari",
    description: "Centro de apoio municipal à mulher vítima de violência doméstica, também chamado de Creas Mulher.",
    categories: %w[cream-cram]
  },
  {
    # https://cram.araxa.mg.gov.br/
    name: "CRAM Araxá", facility_type: "CREAM/CRAM", municipality: "Araxá",
    description: "Centro de Referência de Atendimento à Mulher de Araxá, com portal próprio (cram.araxa.mg.gov.br).",
    categories: %w[cream-cram]
  },
  {
    # Lei Nº 1.688/2022 - Prefeitura Municipal de Areado
    name: "Sala de Atendimento à Mulher Racielle Moreira de Sousa", facility_type: "DEAM",
    municipality: "Areado",
    description: "Sala de atendimento à mulher no prédio da Delegacia de Polícia Civil da Comarca de Areado " \
      "(equipamento equivalente a uma DEAM, criado pela Lei nº 1.688/2022).",
    categories: %w[deam]
  },
  {
    # facebook.com/PrefeituraMunicipaldeCaete/posts/751382187033355/
    name: "Espaço Mulher+", facility_type: "Casa de Apoio", municipality: "Caeté",
    description: "Oferece acolhimento, auxílio-aluguel e abrigo seguro para mulheres vítimas de violência em Caeté.",
    categories: %w[casa-de-abrigo]
  },
  {
    # agenciaminas.mg.gov.br/noticia/policia-civil-de-minas-gerais-inaugura-delegacias-da-mulher-e-rural-em-campo-belo
    name: "DEAM Campo Belo", facility_type: "DEAM", municipality: "Campo Belo",
    address: "Rua Arthur Bernardes, 9", neighborhood: "Centro",
    description: "Inaugurada em 06/06/2025 pela Polícia Civil de Minas Gerais.",
    categories: %w[deam]
  },
  {
    # Fonte: Portal TRT-MG / TRT-3
    name: "DEAM Caratinga", facility_type: "DEAM", municipality: "Caratinga",
    address: "Rua João Caetano Nascimento, 717", neighborhood: "Limoeiro", phone: "(33) 3322-6500",
    description: "Um dos poucos municípios da região com Delegacia Especializada de Atendimento à Mulher própria.",
    categories: %w[deam]
  },
  {
    # carmodacachoeira.mg.gov.br/portal/telefones
    name: "Clínica da Mulher", facility_type: "Clínica da Mulher", municipality: "Carmo da Cachoeira",
    phone: "(35) 9 9841-8956",
    description: "Atendimento de ginecologia, pré-natal, odontologia e psicologia para mulheres do município, " \
      "inaugurada em 2022.",
    categories: %w[atendimento-psicologico]
  },
  {
    # conselheirolafaiete.mg.gov.br/v2/contatos/
    name: "Centro de Referência da Mulher (CRM)", facility_type: "CREAM/CRAM",
    municipality: "Conselheiro Lafaiete",
    description: "Estrutura municipal de acolhimento e atendimento às mulheres de Conselheiro Lafaiete.",
    categories: %w[cream-cram]
  },
  {
    # portal.contagem.mg.gov.br/politica-publica-municipal-para-mulheres-de-contagem
    name: "CEAM Bem-Me-Quero", facility_type: "CREAM/CRAM", municipality: "Contagem",
    description: "Centro Especializado de Atendimento à Mulher em Situação de Violência Doméstica e Familiar, " \
      "vinculado à Secretaria Municipal da Mulher e da Juventude de Contagem.",
    categories: %w[cream-cram]
  },
  {
    # docs/Análise dos links de politicas das mulheres em MG - Municipios A até G.pdf
    name: "DEAM Contagem", facility_type: "DEAM", municipality: "Contagem",
    description: "Delegacia Especializada de Atendimento à Mulher, citada em material institucional da rede " \
      "municipal de proteção à mulher de Contagem.",
    categories: %w[deam]
  },
  {
    # docs/Análise dos links de politicas das mulheres em MG - Municipios A até G.pdf
    name: "Casa de Apoio à Mulher – Sala Borboleta", facility_type: "Casa de Apoio", municipality: "Extrema",
    address: "Estrada Municipal Fazenda Fabiano, 159", neighborhood: "Ponte Nova",
    description: "Programa municipal \"Casa de Apoio à Mulher – Sala Borboleta por Daniela Pinheiro da Silva\": " \
      "acolhimento humanizado, orientação jurídica e articulação com a rede de proteção, inaugurada em 05/03/2026.",
    categories: %w[casa-de-abrigo]
  },
  {
    # Fonte: TRT-MG
    name: "DEAM Formiga", facility_type: "DEAM", municipality: "Formiga",
    address: "Rua Joaquim Fernandes Sobrinho, 150", neighborhood: "Del Rey", phone: "(37) 3329-2350",
    categories: %w[deam]
  },
  {
    # policiacivil.mg.gov.br/noticia/exibir?id=4043779
    name: "DEAM Frutal", facility_type: "DEAM", municipality: "Frutal",
    description: "Delegacia da Mulher em funcionamento na nova Delegacia Regional de Polícia Civil de Frutal " \
      "(inaugurada em 16/04/2026), com jurisdição também sobre Comendador Gomes, Planura, Fronteira, Itapagipe " \
      "e São Francisco de Sales.",
    categories: %w[deam]
  },
  {
    # camaraguaxupe.mg.gov.br/noticia/guaxupe-ganha-nova-sede-da-delegacia-especializada-de-atendimento-a-mulher-47
    name: "DEAM Guaxupé", facility_type: "DEAM", municipality: "Guaxupé",
    address: "Alameda das Rosas, 10", neighborhood: "Parque das Orquídeas",
    opening_hours: "Segunda a sexta, 8h às 12h e 14h às 18h",
    description: "Nova sede inaugurada em 07/03/2024, parceria entre a Polícia Civil e o município.",
    categories: %w[deam]
  },
  {
    # valadares.mg.gov.br/organograma
    name: "Casa de Passagem Feminina", facility_type: "Casa de Apoio", municipality: "Governador Valadares",
    description: "Acolhimento temporário a adolescentes e mulheres em situação de risco pessoal, social ou de " \
      "abandono, unidade da Secretaria de Assistência Social de Governador Valadares.",
    categories: %w[casa-de-abrigo]
  },
  {
    # valadares.mg.gov.br/organograma
    name: "Conselho da Mulher (Governador Valadares)", facility_type: "Conselho da Mulher",
    municipality: "Governador Valadares",
    address: "Rua Pedro Lessa, 364", neighborhood: "Lourdes", phone: "(33) 3272-2613",
    description: "Unidade da Secretaria de Assistência Social onde mulheres podem apresentar denúncias de " \
      "violência ou discriminação.",
    categories: []
  },
  {
    # docs/Análise dos links de politicas das mulheres em MG - Municipios A até G.pdf
    name: "Centro Especializado de Atendimento à Mulher – Benvinda", facility_type: "CREAM/CRAM",
    municipality: "Belo Horizonte",
    description: "Acolhimento e acompanhamento interdisciplinar (psicológico, social e orientação jurídica) " \
      "para mulheres em situação de violência em Belo Horizonte.",
    categories: %w[cream-cram]
  },
  {
    # docs/Análise dos links de politicas das mulheres em MG - Municipios A até G.pdf
    name: "CREAM Betim", facility_type: "CREAM/CRAM", municipality: "Betim",
    description: "Centro de Referência Especializado de Atendimento à Mulher de Betim.",
    categories: %w[cream-cram]
  },
  {
    # docs/Análise dos links de politicas das mulheres em MG - Municipios A até G.pdf
    name: "Casa Jackeline Oliveira", facility_type: "Casa de Apoio", municipality: "Betim",
    description: "Primeira Unidade de Acolhimento Institucional para Mulheres Vítimas de Violência de Betim.",
    categories: %w[casa-de-abrigo]
  },
  {
    # bomdespacho.mg.gov.br/noticias/esta-inaugurada-a-delegacia-especializada-em-atendimento-a-mulher/
    name: "DEAM Bom Despacho", facility_type: "DEAM", municipality: "Bom Despacho",
    description: "Delegacia Especializada em Atendimento à Mulher, com atendimento multidisciplinar.",
    categories: %w[deam]
  }
]

real_facilities.each do |attrs|
  municipality = Territorial::Municipality.find_by!(name: attrs[:municipality])

  facility = Territorial::Facility.find_or_create_by!(name: attrs[:name]) do |f|
    f.facility_type = attrs[:facility_type]
    f.municipality = municipality
    f.address = attrs[:address]
    f.neighborhood = attrs[:neighborhood]
    f.cep = attrs[:cep]
    f.phone = attrs[:phone]
    f.opening_hours = attrs[:opening_hours]
    f.description = attrs[:description]
  end

  categories = Territorial::ServiceCategory.where(slug: attrs[:categories])
  facility.service_categories = categories if facility.service_categories.empty?
end

puts "  #{Territorial::Facility.count} equipamentos cadastrados."

# GeocodeFacilityJob é enfileirado via after_commit (perform_later), mas o
# adapter :async padrão do ambiente de desenvolvimento roda num thread pool
# preso ao processo — como `db:seed` é um processo curto que termina logo em
# seguida, o job nunca chega a rodar e o equipamento fica sem coordenadas.
# Geocodificar de forma síncrona aqui garante que o seed sempre termina com
# equipamentos já no mapa, independente do adapter de fila configurado.
Territorial::Facility.where(latitude: nil).find_each { |f| GeocodeFacilityJob.perform_now(f.id) }
puts "  #{Territorial::Facility.where.not(latitude: nil).count} equipamentos geocodificados."

# ---------------------------------------------------------------------------
# Parceiros (Partners::Partner): diferente dos equipamentos acima, nenhum
# parceiro real foi levantado ainda — nenhum parceiro fictício é criado aqui.
# A lista real "será fornecida pela equipe" (PDF original); até lá, a página
# de Rede Maria Mineira cai no estado vazio honesto.
# ---------------------------------------------------------------------------
puts "Partners::Partner permanece vazio de propósito (ver comentário acima)."

# ---------------------------------------------------------------------------
# Admin::User inicial — só em desenvolvimento, para permitir o primeiro login
# no CMS. Em produção, contas administrativas devem ser criadas manualmente
# (bin/rails console) por alguém com acesso ao ambiente — nunca via seed.
# ---------------------------------------------------------------------------
if Rails.env.development? && Admin::User.count.zero?
  password = SecureRandom.alphanumeric(14)
  Admin::User.create!(
    email_address: "admin@mariamineira.com.br",
    password: password,
    password_confirmation: password,
    role: :super_admin
  )
  puts "Admin::User inicial criado (ambiente de desenvolvimento):"
  puts "  e-mail: admin@mariamineira.com.br"
  puts "  senha:  #{password}"
end
