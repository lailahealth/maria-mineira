class CreatePartnersPartners < ActiveRecord::Migration[8.1]
  def change
    create_table :partners_partners do |t|
      t.string :name, null: false
      t.string :partner_type, null: false
      t.text :description
      t.string :url
      t.string :coverage_scope
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :partners_partners, :partner_type
    add_index :partners_partners, :active
  end
end
