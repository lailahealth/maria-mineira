class CreateTaxonomyTags < ActiveRecord::Migration[8.1]
  def change
    create_table :taxonomy_tags do |t|
      t.string :slug, null: false
      t.string :label, null: false
      t.integer :kind, null: false, default: 0
      t.references :parent, foreign_key: { to_table: :taxonomy_tags }
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :taxonomy_tags, :slug, unique: true
  end
end
