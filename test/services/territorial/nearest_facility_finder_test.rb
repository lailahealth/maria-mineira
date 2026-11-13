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

  test "a busca genérica inclui UBS, mas depois dos serviços especializados" do
    ubs_category = Territorial::ServiceCategory.create!(name: "UBS", slug: "ubs-teste")
    ubs = Territorial::Facility.create!(name: "A UBS Centro", facility_type: "UBS", municipality: @uberlandia,
                                        active: true, service_categories: [ ubs_category ])
    deam = Territorial::Facility.create!(name: "Z DEAM", facility_type: "DEAM", municipality: @uberlandia, active: true)
    saude = Territorial::Facility.create!(name: "Hospital", facility_type: "Unidade de Saúde", municipality: @uberlandia, active: true)

    finder = Territorial::NearestFacilityFinder.new(municipality: @uberlandia)
    assert_equal [ deam, saude, @facility, ubs ], finder.call
    assert_nil finder.matched_category
    assert_not finder.more?
  end

  test "pagina de 5 em 5 e diz se há mais" do
    7.times { |i| Territorial::Facility.create!(name: "UBS #{i}", facility_type: "UBS", municipality: @uberlandia, active: true) }

    first = Territorial::NearestFacilityFinder.new(municipality: @uberlandia)
    assert_equal 5, first.call.size
    assert first.more?

    second = Territorial::NearestFacilityFinder.new(municipality: @uberlandia, offset: 5)
    page = second.call
    assert_equal 3, page.size
    assert_not second.more?
    assert_empty first.call & page
  end

  test "página seguinte de uma categoria não cai para a busca genérica" do
    deam = Territorial::ServiceCategory.create!(name: "DEAM", slug: "deam-teste")
    Territorial::Facility.create!(name: "DEAM", facility_type: "deam", municipality: @uberlandia,
                                  active: true, service_categories: [ deam ])

    finder = Territorial::NearestFacilityFinder.new(service_category: deam, municipality: @uberlandia, offset: 5)
    assert_empty finder.call
    assert_equal deam, finder.matched_category
  end
end
