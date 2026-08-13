class CreateJourneyEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :journey_events do |t|
      t.references :journey_session, null: false, foreign_key: true, type: :uuid
      t.integer :event_type, null: false
      t.string :tag
      t.string :subtag
      t.string :municipality_ibge_code
      t.string :categoria_servico
      t.bigint :equipamento_indicado_id
      t.string :equipamento_indicado_nome
      t.integer :resultado
      t.float :distancia_aproximada_km

      t.datetime :created_at, null: false
    end

    add_index :journey_events, :event_type
    add_index :journey_events, :tag
    add_index :journey_events, :municipality_ibge_code
  end
end
