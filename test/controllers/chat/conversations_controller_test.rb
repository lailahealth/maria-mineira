require "test_helper"

class Chat::ConversationsControllerTest < ActionDispatch::IntegrationTest
  MODERN_USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"

  test "abrir o chat grava um evento chat_aberto" do
    get chat_path, headers: { "User-Agent" => MODERN_USER_AGENT }

    assert_response :success
    assert_equal 1, Journey::Event.chat_aberto.count
  end

  test "abrir o chat de novo na mesma sessão não duplica o evento" do
    get chat_path, headers: { "User-Agent" => MODERN_USER_AGENT }
    get chat_path, headers: { "User-Agent" => MODERN_USER_AGENT }

    assert_equal 1, Journey::Event.chat_aberto.count
  end
end
