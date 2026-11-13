require "test_helper"

class MapControllerTest < ActionDispatch::IntegrationTest
  setup do
    @uberlandia = Territorial::Municipality.create!(ibge_code: "3170206", name: "Uberlândia")
    @ubs = Territorial::ServiceCategory.create!(name: "Unidade Básica de Saúde (UBS)", slug: "ubs")
    2.times do |i|
      Territorial::Facility.create!(name: "UBS #{i}", facility_type: "UBS", municipality: @uberlandia,
                                    active: true, service_categories: [ @ubs ], latitude: -18.9, longitude: -48.2)
    end
  end

  test "busca só por categoria lista os equipamentos do estado quando são poucos" do
    get map_page_path(categoria: "ubs")

    assert_response :success
    assert_match "2 equipamentos encontrados", response.body
  end

  test "busca só por categoria pede um município quando o estado tem resultados demais" do
    original = MapController::STATEWIDE_LIMIT
    MapController.send(:remove_const, :STATEWIDE_LIMIT)
    MapController.const_set(:STATEWIDE_LIMIT, 1)

    get map_page_path(categoria: "ubs")

    assert_response :success
    assert_match "Escolha um município", response.body
    assert_no_match "UBS 0", response.body
  ensure
    MapController.send(:remove_const, :STATEWIDE_LIMIT)
    MapController.const_set(:STATEWIDE_LIMIT, original)
  end

  test "pagina os cartões de 10 em 10, mas o mapa recebe todos os pontos" do
    10.times do |i|
      Territorial::Facility.create!(name: "UBS Extra #{i}", facility_type: "UBS", municipality: @uberlandia,
                                    active: true, service_categories: [ @ubs ], latitude: -18.9, longitude: -48.2)
    end

    get map_page_path(municipio: "Uberlândia", categoria: "ubs")
    assert_match "12 equipamentos encontrados", response.body
    assert_equal 10, css_select("a[href^='/mapa/equipamentos/'].rounded-2xl").size
    assert_equal 12, JSON.parse(css_select("[data-controller=map]").first["data-map-facilities-value"]).size
    assert_match "1–10 de 12", response.body
    assert_select "a[href*='page=2'][href$='#resultados']", text: "Próxima →"

    get map_page_path(municipio: "Uberlândia", categoria: "ubs", page: 2)
    assert_equal 2, css_select("a[href^='/mapa/equipamentos/'].rounded-2xl").size
    assert_equal 12, JSON.parse(css_select("[data-controller=map]").first["data-map-facilities-value"]).size
  end

  test "com município, mostra tudo da cidade" do
    get map_page_path(municipio: "Uberlândia", categoria: "ubs")

    assert_response :success
    assert_match "2 equipamentos encontrados", response.body
  end
end
