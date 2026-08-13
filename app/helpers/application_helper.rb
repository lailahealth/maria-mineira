module ApplicationHelper
  # Menu principal da Maria Mineira (seção 25 do parecer técnico).
  # "Converse com a Maria Mineira" tem CTA própria no header, por isso não repete aqui.
  def main_nav_links
    {
      "Início" => root_path,
      "Encontre um serviço" => service_search_path,
      "Mapa" => map_page_path,
      "Tipos de violência" => violence_types_path,
      "Direitos" => rights_path,
      "Políticas e programas" => policies_path,
      "Rede Maria Mineira" => partners_path,
      "Sobre" => about_path
    }
  end

  def content_page_path(page)
    case page.content_type
    when "tipo_violencia" then violence_type_path(page)
    when "direito" then right_path(page)
    else policy_path(page)
    end
  end
end
