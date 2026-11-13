module Territorial
  # Adequação + proximidade (seção 8 do parecer técnico): o equipamento mais próximo só
  # é sugerido se também for da categoria de serviço adequada à necessidade identificada.
  # Se essa categoria não tiver nada cadastrado na região, cai para os equipamentos de
  # qualquer categoria: várias categorias (orientacao-juridica, central-180) ainda não
  # têm nenhum equipamento cadastrado, e "moro em Uberlândia, quais meus direitos?"
  # respondia "não temos serviços" mesmo com CRAS, CREAS e DEAM na cidade.
  #
  # Ordem em rodadas por tipo de equipamento: primeiro o mais perto de cada tipo
  # (DEAM, CREAM/CRAM, CREAS, saúde, CRAS, UBS — nessa prioridade), depois o
  # segundo mais perto de cada tipo, e assim por diante. Só por distância, as UBS
  # (uma por bairro) ocupariam as primeiras sugestões; só por prioridade, a
  # primeira página em BH seriam DEAMs de outras cidades a 15 km e as UBS ficariam
  # na 11ª página. Sem coordenada (busca por município), "mais perto" vira o nome.
  #
  # Pagina de PAGE_SIZE em PAGE_SIZE (o chat mostra "Ver mais"): #call devolve a
  # página pedida por offset, #more? diz se há outra e #matched_category diz qual
  # categoria foi de fato usada (nil = busca genérica), para a página seguinte
  # repetir exatamente a mesma busca.
  class NearestFacilityFinder
    DEFAULT_RADIUS_KM = 50
    PAGE_SIZE = 5
    NEARBY_KM = 10

    PRIORITY_BY_TYPE = {
      "DEAM" => 0,
      "CREAM/CRAM" => 1, "CASA DA MULHER" => 1,
      "CREAS" => 2,
      "UNIDADE DE SAÚDE" => 3, "CLÍNICA DA MULHER" => 3,
      "CASA DE APOIO" => 4, "CONSELHO DA MULHER" => 4,
      "CRAS" => 6,
      "UBS" => 7
    }.freeze
    DEFAULT_PRIORITY = 5

    attr_reader :matched_category

    def initialize(service_category: nil, municipality: nil, lat: nil, lng: nil,
                   radius_km: DEFAULT_RADIUS_KM, offset: 0)
      @service_category = service_category
      @municipality = municipality
      @lat = lat
      @lng = lng
      @radius_km = radius_km
      @offset = offset.to_i
      @more = false
    end

    def call
      if @service_category
        adequate = search(Territorial::Facility.active.joins(:service_categories)
          .where(territorial_service_categories: { id: @service_category.id }))
        # Numa página seguinte (offset > 0) não cai para a busca genérica: misturaria
        # outra lista no meio da que a pessoa está vendo.
        if adequate.any? || @offset.positive?
          @matched_category = @service_category
          return adequate
        end
      end

      @matched_category = nil
      search(Territorial::Facility.active)
    end

    def more?
      @more
    end

    private

    def search(scope)
      ranked =
        if @lat.present? && @lng.present?
          point = "ST_SetSRID(ST_MakePoint(#{@lng.to_f}, #{@lat.to_f}), 4326)::geography"
          distance = "ST_Distance(territorial_facilities.location, #{point})"
          scope.where.not(location: nil)
            .where("ST_DWithin(territorial_facilities.location, #{point}, ?)", @radius_km * 1000)
            .select("territorial_facilities.*, #{distance} AS distance_meters, " \
                    "ROW_NUMBER() OVER (PARTITION BY #{type_key_sql} ORDER BY #{distance}) AS type_round")
        elsif @municipality
          scope.where(municipality_id: @municipality.id)
            .select("territorial_facilities.*, " \
                    "ROW_NUMBER() OVER (PARTITION BY #{type_key_sql} ORDER BY LOWER(territorial_facilities.name)) AS type_round")
        end
      return [] unless ranked

      # Dentro de cada rodada, o que está longe (> NEARBY_KM) vai para o fim: sem
      # isso, uma Casa de Apoio a 17 km entrava antes do CRAS e da UBS a 1 km.
      order =
        if @lat.present? && @lng.present?
          "type_round, (distance_meters > #{NEARBY_KM * 1000}), #{priority_sql}, distance_meters"
        else
          "type_round, #{priority_sql}, LOWER(territorial_facilities.name)"
        end
      rows = Territorial::Facility.from(ranked, :territorial_facilities)
        .order(Arel.sql(order))
        .offset(@offset).limit(PAGE_SIZE + 1).to_a
      @more = rows.size > PAGE_SIZE
      rows.first(PAGE_SIZE)
    end

    def type_key_sql
      "UPPER(territorial_facilities.facility_type)"
    end

    def priority_sql
      connection = Territorial::Facility.connection
      # UPPER do Postgres só converte "ú" em "Ú" com collation UTF-8; com "C" fica
      # "ú". Gera as duas grafias de cada tipo para não depender da collation.
      whens = PRIORITY_BY_TYPE.flat_map { |type, rank|
        [ type, type.downcase.tr("a-z", "A-Z") ].uniq.map { |t| "WHEN #{connection.quote(t)} THEN #{rank}" }
      }.join(" ")
      "CASE UPPER(territorial_facilities.facility_type) #{whens} ELSE #{DEFAULT_PRIORITY} END"
    end
  end
end
