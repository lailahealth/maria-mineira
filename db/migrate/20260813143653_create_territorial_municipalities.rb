class CreateTerritorialMunicipalities < ActiveRecord::Migration[8.1]
  def change
    create_table :territorial_municipalities do |t|
      t.string :ibge_code, null: false
      t.string :name, null: false
      t.string :region
      t.string :state, null: false, default: "MG"

      t.timestamps
    end

    add_index :territorial_municipalities, :ibge_code, unique: true
    add_index :territorial_municipalities, :name
  end
end
