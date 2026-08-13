class CreateTerritorialServiceCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :territorial_service_categories do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.references :taxonomy_tag, foreign_key: true

      t.timestamps
    end

    add_index :territorial_service_categories, :slug, unique: true
  end
end
