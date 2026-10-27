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

  test "recent_conversas mostra a cidade buscada em cada conversa, não a última da sessão" do
    Territorial::Municipality.create!(ibge_code: "3136702", name: "Juiz de Fora")
    Territorial::Municipality.create!(ibge_code: "3170206", name: "Uberlândia")
    session = Journey::Session.create!(started_at: 1.hour.ago)
    sem_busca = Journey::Event.create!(session: session, event_type: :motivo, created_at: 50.minutes.ago)
    em_uberlandia = Journey::Event.create!(session: session, event_type: :motivo, created_at: 40.minutes.ago)
    Journey::Event.create!(session: session, event_type: :busca_servico, municipality_ibge_code: "3170206", created_at: 39.minutes.ago)
    em_juiz_de_fora = Journey::Event.create!(session: session, event_type: :motivo, created_at: 30.minutes.ago)
    Journey::Event.create!(session: session, event_type: :busca_servico, municipality_ibge_code: "3136702", created_at: 29.minutes.ago)

    municipio_por_conversa = Journey::DashboardReport.new.recent_conversas.to_h { |row| [ row[:at].to_i, row[:municipio] ] }

    assert_nil municipio_por_conversa[sem_busca.created_at.to_i]
    assert_equal "Uberlândia", municipio_por_conversa[em_uberlandia.created_at.to_i]
    assert_equal "Juiz de Fora", municipio_por_conversa[em_juiz_de_fora.created_at.to_i]
  end
end
