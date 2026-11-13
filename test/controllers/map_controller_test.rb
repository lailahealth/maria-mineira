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

  test "com município, mostra tudo da cidade" do
    get map_page_path(municipio: "Uberlândia", categoria: "ubs")

    assert_response :success
    assert_match "2 equipamentos encontrados", response.body
  end
end
