require "test_helper"

class ChatHelperTest < ActionView::TestCase
  test "explica a unidade de saúde de referência para violência sexual" do
    municipality = Territorial::Municipality.create!(ibge_code: "3170206", name: "Uberlândia")
    facility = Territorial::Facility.new(name: "Hospital de Clínicas", facility_type: "Unidade de Saúde",
                                         municipality: municipality)

    assert_match(/violência sexual/, facility_type_explanation(facility))
    assert_match(/72 horas/, facility_type_explanation(facility))
  end

  test "explica a UBS sem confundir com a referência em violência sexual" do
    municipality = Territorial::Municipality.create!(ibge_code: "3170206", name: "Uberlândia")
    facility = Territorial::Facility.new(name: "UBS Centro", facility_type: "UBS", municipality: municipality)

    assert_match(/Posto de saúde/, facility_type_explanation(facility))
    assert_no_match(/72 horas/, facility_type_explanation(facility))
  end
end
