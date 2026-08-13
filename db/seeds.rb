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
# Equipamentos (Territorial::Facility): propositalmente NENHUM equipamento fictício
# é criado aqui. A base real "será fornecida pela equipe" (PDF original) — até lá,
# toda busca deve cair no fluxo "ainda não temos informações suficientes" (seção 11).
# ---------------------------------------------------------------------------
puts "Seed concluído. Territorial::Facility permanece vazio de propósito (ver comentário acima)."

# ---------------------------------------------------------------------------
# Parceiros (Partners::Partner): mesma política do Territorial::Facility acima —
# nenhum parceiro fictício é criado. A lista real "será fornecida pela equipe"
# (PDF original); até lá, a página de Rede Maria Mineira cai no estado vazio honesto.
# ---------------------------------------------------------------------------
puts "Partners::Partner permanece vazio de propósito (ver comentário acima)."
