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
