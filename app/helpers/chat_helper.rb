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
end
