require "test_helper"

class Journey::DashboardReportTest < ActiveSupport::TestCase
  test "campaigns inclui abriram_chat entre sessões e escreveram" do
    session = Journey::Session.create!(started_at: Time.current, plataforma_origem: "instagram", campanha: "campanha_teste")
    Journey::EventRecorder.record(session: session, event_type: :chat_aberto)

    row = Journey::DashboardReport.new.campaigns.find { |r| r[:campanha] == "campanha_teste" }

    assert_equal 1, row[:sessoes]
    assert_equal 1, row[:abriram_chat]
    assert_equal 0, row[:escreveram]
  end

  test "abriram_chat não conta sessão que não abriu o chat" do
    Journey::Session.create!(started_at: Time.current, plataforma_origem: "instagram", campanha: "sem_chat")

    row = Journey::DashboardReport.new.campaigns.find { |r| r[:campanha] == "sem_chat" }

    assert_equal 0, row[:abriram_chat]
  end
end
