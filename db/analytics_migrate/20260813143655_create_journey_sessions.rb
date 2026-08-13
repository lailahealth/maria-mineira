class CreateJourneySessions < ActiveRecord::Migration[8.1]
  def change
    create_table :journey_sessions, id: :uuid do |t|
      t.datetime :started_at, null: false
      t.string :tag_origem
      t.string :subtag_origem
      t.string :plataforma_origem
      t.string :campanha
      t.string :conteudo_origem
      t.string :pagina_entrada
      t.string :municipality_ibge_code
      t.string :device_hint

      t.timestamps
    end
  end
end
