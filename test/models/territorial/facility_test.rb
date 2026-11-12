require "test_helper"

class Territorial::FacilityTest < ActiveSupport::TestCase
  setup do
    @municipality = Territorial::Municipality.create!(ibge_code: "3170206", name: "Uberlândia")
  end

  test "normaliza o CNES para só dígitos e impede CNES repetido" do
    ubs = Territorial::Facility.create!(name: "UBS Centro", facility_type: "Unidade de Saúde",
                                        municipality: @municipality, cnes: " 2146.355 ")
    assert_equal "2146355", ubs.cnes

    duplicate = Territorial::Facility.new(name: "UBS Centro 2", facility_type: "Unidade de Saúde",
                                          municipality: @municipality, cnes: "2146355")
    assert_not duplicate.valid?
  end

  test "equipamentos sem CNES (DEAM, CRAS…) não colidem entre si" do
    Territorial::Facility.create!(name: "CRAS A", facility_type: "CRAS", municipality: @municipality, cnes: "")
    assert Territorial::Facility.new(name: "CRAS B", facility_type: "CRAS", municipality: @municipality, cnes: nil).valid?
  end
end
