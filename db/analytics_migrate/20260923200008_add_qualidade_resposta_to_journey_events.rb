class AddQualidadeRespostaToJourneyEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :journey_events, :qualidade_resposta, :integer
  end
end
