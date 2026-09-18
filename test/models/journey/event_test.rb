require "test_helper"

class Journey::EventTest < ActiveSupport::TestCase
  test "chat_aberto é um event_type válido" do
    session = Journey::Session.create!(started_at: Time.current)
    event = Journey::Event.create!(session: session, event_type: :chat_aberto)

    assert event.chat_aberto?
  end
end
