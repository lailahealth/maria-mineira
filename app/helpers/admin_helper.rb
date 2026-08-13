module AdminHelper
  FIELD_LABEL = "text-sm font-semibold text-presenca"
  FIELD_INPUT = "mt-1.5 block w-full rounded-xl border border-blush px-3.5 py-2.5 text-sm text-presenca focus:border-vinho focus:outline-none"
  FIELD_CHECKBOX = "rounded border-blush text-vinho focus:ring-vinho"
  BUTTON_PRIMARY = "inline-flex items-center justify-center rounded-full bg-vinho px-5 py-2.5 text-sm font-semibold text-offwhite hover:bg-vinho/90"
  BUTTON_SECONDARY = "inline-flex items-center justify-center rounded-full border border-blush px-5 py-2.5 text-sm font-semibold text-presenca hover:border-vinho hover:text-vinho"

  ROLE_LABELS = {
    "super_admin" => "Administradora geral",
    "content_editor" => "Editora de conteúdo",
    "data_analyst" => "Analista de dados",
    "partner_manager" => "Gestora de parceiros"
  }.freeze

  CONTENT_TYPE_LABELS = {
    "tipo_violencia" => "Tipo de violência",
    "direito" => "Direito",
    "politica" => "Política pública",
    "programa" => "Programa",
    "servico_info" => "Informação sobre serviço",
    "campanha" => "Campanha",
    "informacao_util" => "Informação útil"
  }.freeze

  # Cada item só aparece para quem pode agir nele — super_admin sempre vê tudo
  # (mesma regra de Admin::BaseController#require_role!).
  def admin_nav_links(user)
    [
      { label: "Painel", path: admin_root_path, roles: %w[super_admin content_editor data_analyst partner_manager] },
      { label: "Conteúdo", path: admin_pages_path, roles: %w[super_admin content_editor] },
      { label: "Taxonomia", path: admin_tags_path, roles: %w[super_admin content_editor] },
      { label: "Equipamentos", path: admin_facilities_path, roles: %w[super_admin content_editor] },
      { label: "Categorias de serviço", path: admin_service_categories_path, roles: %w[super_admin content_editor] },
      { label: "Municípios", path: admin_municipalities_path, roles: %w[super_admin content_editor data_analyst] },
      { label: "Parceiros", path: admin_partners_path, roles: %w[super_admin partner_manager] },
      { label: "Administradoras", path: admin_users_path, roles: %w[super_admin] }
    ].select { |item| user.super_admin? || item[:roles].include?(user.role) }
  end
end
