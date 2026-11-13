require "test_helper"

class Territorial::NearestFacilityFinderTest < ActiveSupport::TestCase
  setup do
    @uberlandia = Territorial::Municipality.create!(ibge_code: "3170206", name: "Uberlândia")
    @cras = Territorial::ServiceCategory.create!(name: "CRAS", slug: "cras-teste")
    @juridica = Territorial::ServiceCategory.create!(name: "Orientação jurídica", slug: "orientacao-juridica-teste")
    @facility = Territorial::Facility.create!(name: "CRAS Centro", facility_type: "cras", municipality: @uberlandia,
                                              active: true, service_categories: [ @cras ])
  end

  test "prefere os equipamentos da categoria adequada quando existem" do
    deam = Territorial::ServiceCategory.create!(name: "DEAM", slug: "deam-teste")
    delegacia = Territorial::Facility.create!(name: "DEAM", facility_type: "deam", municipality: @uberlandia,
                                              active: true, service_categories: [ deam ])

    assert_equal [ delegacia ], Territorial::NearestFacilityFinder.new(service_category: deam, municipality: @uberlandia).call
  end

  test "sem nada da categoria adequada na cidade, mostra os outros equipamentos" do
    assert_equal [ @facility ], Territorial::NearestFacilityFinder.new(service_category: @juridica, municipality: @uberlandia).call
  end

  test "a busca genérica não sugere UBS, mas o filtro pela categoria UBS sim" do
    ubs_category = Territorial::ServiceCategory.create!(name: "UBS", slug: "ubs")
    ubs = Territorial::Facility.create!(name: "UBS Centro", facility_type: "UBS", municipality: @uberlandia,
                                        active: true, service_categories: [ ubs_category ])

    assert_equal [ @facility ], Territorial::NearestFacilityFinder.new(service_category: @juridica, municipality: @uberlandia).call
    assert_equal [ @facility ], Territorial::NearestFacilityFinder.new(municipality: @uberlandia).call
    assert_equal [ ubs ], Territorial::NearestFacilityFinder.new(service_category: ubs_category, municipality: @uberlandia).call
  end
end
