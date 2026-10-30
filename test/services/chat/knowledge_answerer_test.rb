require "test_helper"

class Chat::KnowledgeAnswererTest < ActiveSupport::TestCase
  test "o histórico entra como turnos alternados começando pela pessoa" do
    history = [
      { role: "assistant", text: "Oi, eu sou a Maria Mineira." },
      { role: "user", text: "meu marido me ofende" },
      { role: "assistant", text: "Isso é violência psicológica." },
      { role: "assistant", text: "Posso buscar serviços na sua cidade." }
    ]

    messages = build_body("o que é medida protetiva?", history: history)[:messages]

    assert_equal %w[user assistant user], messages.map { |m| m[:role] }
    assert_equal "meu marido me ofende", messages.first[:content]
    assert_includes messages.second[:content], "Posso buscar serviços"
    assert_equal "o que é medida protetiva?", messages.last[:content]
  end

  test "o contexto de localização vem depois do bloco em cache" do
    itabira = Territorial::Municipality.new(name: "Itabira")

    system = build_body("oi", municipality: itabira)[:system]

    assert system.second.key?(:cache_control)
    assert_not system.last.key?(:cache_control)
    assert_includes system.last[:text], "Itabira"
  end

  test "sem município, a IA é avisada para não presumir cidade" do
    assert_includes build_body("oi")[:system].last[:text], "Não presuma nenhuma cidade"
  end

  private

  def build_body(text, **options)
    Chat::KnowledgeAnswerer.new.send(:build_body, text, **options)
  end
end
