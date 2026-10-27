require "test_helper"

class Territorial::LocationResolverTest < ActiveSupport::TestCase
  setup do
    @juiz_de_fora = Territorial::Municipality.create!(ibge_code: "3136702", name: "Juiz de Fora")
    @uberlandia = Territorial::Municipality.create!(ibge_code: "3170206", name: "Uberlândia")
    @belo_horizonte = Territorial::Municipality.create!(ibge_code: "3106200", name: "Belo Horizonte")
    Territorial::Municipality.create!(ibge_code: "3111804", name: "Casa Grande")
  end

  test "extract reconhece a cidade escrita do jeito que a pessoa fala" do
    [
      "Juiz de Fora", "Estou em Juiz de Fora", "estou em juiz de fora.", "Sou de Juiz de Fora - MG",
      "Juiz de Fora, MG", "Oi, estou em Juiz de Fora", "minha cidade é Juiz de Fora", "moro em jf",
      "estou em Juis de Fora"
    ].each do |text|
      assert_equal @juiz_de_fora, Territorial::LocationResolver.extract(text)[:municipality], text
    end
  end

  test "extract devolve o resto da mensagem quando ela também traz uma pergunta" do
    result = Territorial::LocationResolver.extract("moro em Uberlândia, quais meus direitos?")

    assert_equal @uberlandia, result[:municipality]
    assert_equal ", quais meus direitos?", result[:remainder]
  end

  test "extract casa nomes compostos sem engolir o resto da frase" do
    result = Territorial::LocationResolver.extract("moro em Juiz de Fora e ele me xinga")

    assert_equal @juiz_de_fora, result[:municipality]
    assert_equal "e ele me xinga", result[:remainder]
  end

  test "extract entende a sigla bh" do
    assert_equal @belo_horizonte, Territorial::LocationResolver.extract("moro em bh")[:municipality]
  end

  test "extract não confunde frases comuns com localização" do
    [
      "tem muita formiga aqui", "estou em casa", "estou em perigo", "sou de confiança", "estou em dúvida",
      "estou na casa da minha mãe", "vivo em um relacionamento abusivo", "moro no interior"
    ].each do |text|
      assert_empty Territorial::LocationResolver.extract(text), text
    end
  end

  test "extract reconhece CEP no meio da frase" do
    cep = Territorial::CepLookup::Result.new(city: "Juiz de Fora", state: "MG", ibge_code: "3136702")

    with_singleton_stub(Territorial::CepLookup, :lookup, cep) do
      with_singleton_stub(Territorial::Geocoder, :geocode, nil) do
        assert_equal @juiz_de_fora, Territorial::LocationResolver.extract("meu CEP é 36010-000")[:municipality]
      end
    end
  end

  test "resolve aceita frase no campo de município" do
    assert_equal @juiz_de_fora, Territorial::LocationResolver.resolve("estou em Juiz de Fora")[:municipality]
  end
end
