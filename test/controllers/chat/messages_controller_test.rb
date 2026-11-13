require "test_helper"

class Chat::MessagesControllerTest < ActionDispatch::IntegrationTest
  MODERN_USER_AGENT = Chat::ConversationsControllerTest::MODERN_USER_AGENT

  setup do
    @juiz_de_fora = Territorial::Municipality.create!(ibge_code: "3136702", name: "Juiz de Fora")
  end

  test "dizer a cidade numa frase no meio da conversa já busca os serviços" do
    without_ai do
      get chat_path, headers: headers
      post chat_messages_path, params: { body: "meu marido me ofende com palavras" }, headers: headers
      post chat_messages_path, params: { body: "Estou em Juiz de Fora" }, headers: headers
    end

    conversation = Chat::Conversation.last
    assert_equal @juiz_de_fora, conversation.municipality
    assert conversation.messages.card_type_municipio_sem_cobertura.exists?
  end

  test "cidade já no primeiro relato mostra os serviços no lugar do lembrete" do
    without_ai do
      get chat_path, headers: headers
      post chat_messages_path, params: { body: "Moro em Juiz de Fora e meu marido me xinga todo dia" }, headers: headers
    end

    conversation = Chat::Conversation.last
    assert_equal @juiz_de_fora, conversation.municipality
    assert_not conversation.messages.card_type_location_prompt.exists?
  end

  test "não moro em BH não busca Belo Horizonte" do
    Territorial::Municipality.create!(ibge_code: "3106200", name: "Belo Horizonte")

    without_ai do
      get chat_path, headers: headers
      post chat_messages_path, params: { body: "meu marido me ofende com palavras" }, headers: headers
      post chat_messages_path, params: { body: "não moro em BH, moro numa cidade pequena" }, headers: headers
    end

    assert_nil Chat::Conversation.last.municipality
  end

  test "o resultado da busca diz qual cidade o chat entendeu" do
    category = Territorial::ServiceCategory.create!(name: "CRAS", slug: "cras-teste")
    Territorial::Facility.create!(name: "CRAS Centro", facility_type: "cras", municipality: @juiz_de_fora,
                                  active: true, service_categories: [ category ])

    without_ai do
      get chat_path, headers: headers
      post chat_messages_path, params: { body: "meu marido me ofende com palavras" }, headers: headers
      post chat_messages_path, params: { body: "Estou em Juiz de Fora" }, headers: headers
    end

    card = Chat::Conversation.last.messages.card_type_facility_results.last
    assert_equal "Encontrei estes serviços em Juiz de Fora:", JSON.parse(card.body)["text"]
  end

  test "com mais de 5 serviços, o card tem Ver mais, que traz os próximos e some" do
    7.times do |i|
      Territorial::Facility.create!(name: "Serviço #{i}", facility_type: "CRAS", municipality: @juiz_de_fora, active: true)
    end

    without_ai do
      get chat_path, headers: headers
      post chat_messages_path, params: { body: "meu marido me ofende com palavras" }, headers: headers
      post chat_messages_path, params: { body: "Estou em Juiz de Fora" }, headers: headers
    end

    first = Chat::Conversation.last.messages.card_type_facility_results.last
    assert_equal 5, JSON.parse(first.body)["facility_ids"].size
    assert_select "#more-facilities-#{first.id} input[type=submit][value='Ver mais']"

    post chat_messages_path, params: { more_facilities: first.id }, headers: headers

    assert_select "turbo-stream[action=remove][target='more-facilities-#{first.id}']"
    second = Chat::Conversation.last.messages.card_type_facility_results.last
    payload = JSON.parse(second.body)
    assert_equal "Mais opções:", payload["text"]
    assert_equal 2, payload["facility_ids"].size
    assert_empty payload["facility_ids"] & JSON.parse(first.reload.body)["facility_ids"]
    assert_not payload.dig("search", "has_more")
    assert_not JSON.parse(first.body).dig("search", "has_more")

    # clicar de novo no card já expandido não repete a lista
    assert_no_difference -> { Chat::Message.count } do
      post chat_messages_path, params: { more_facilities: first.id }, headers: headers
    end
  end

  test "frase comum não vira busca por localização" do
    without_ai do
      get chat_path, headers: headers
      post chat_messages_path, params: { body: "meu marido me ofende com palavras" }, headers: headers
      post chat_messages_path, params: { body: "estou em casa agora" }, headers: headers
    end

    assert_nil Chat::Conversation.last.municipality
  end

  private

  def headers
    { "User-Agent" => MODERN_USER_AGENT, "Accept" => "text/vnd.turbo-stream.html" }
  end

  def without_ai(&block)
    with_singleton_stub(Chat::KnowledgeAnswerer, :api_key, nil) do
      with_singleton_stub(Classification::LlmClassifier, :api_key, nil, &block)
    end
  end
end
