require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  MODERN_USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"

  test "UTM é gravado na primeira visita" do
    get root_path, params: { utm_source: "instagram", utm_campaign: "campanha_a", utm_content: "story" },
                    headers: { "User-Agent" => MODERN_USER_AGENT }

    session = Journey::Session.order(:created_at).last
    assert_equal "instagram", session.plataforma_origem
    assert_equal "campanha_a", session.campanha
  end

  test "nova chegada com UTM diferente sobrescreve a sessão existente (último toque)" do
    get root_path, params: { utm_source: "instagram", utm_campaign: "campanha_a" },
                    headers: { "User-Agent" => MODERN_USER_AGENT }
    get root_path, params: { utm_source: "facebook", utm_campaign: "campanha_b" },
                    headers: { "User-Agent" => MODERN_USER_AGENT }

    assert_equal 1, Journey::Session.count
    session = Journey::Session.last
    assert_equal "facebook", session.plataforma_origem
    assert_equal "campanha_b", session.campanha
  end

  test "visita sem UTM depois de uma sessão sem UTM continua sem campanha" do
    get root_path, headers: { "User-Agent" => MODERN_USER_AGENT }
    get root_path, headers: { "User-Agent" => MODERN_USER_AGENT }

    assert_equal 1, Journey::Session.count
    assert_nil Journey::Session.last.campanha
  end
end
