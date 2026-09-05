module Chat
  # Conteúdo das cartilhas do projeto Mulheres de Minas (docs/Cartilhas), extraído
  # e revisado uma única vez para texto simples. Serve de contexto para
  # Chat::KnowledgeAnswerer — a resposta gerada nunca deve citar a cartilha de
  # origem, então aqui só existe o conteúdo combinado, sem nomes de arquivo.
  module KnowledgeBase
    CARTILHAS_DIR = Rails.root.join("app/services/chat/knowledge_base/cartilhas")

    def self.combined_text
      Dir.glob(CARTILHAS_DIR.join("*.txt")).sort.map { |path| File.read(path) }.join("\n\n---\n\n")
    end
  end
end
