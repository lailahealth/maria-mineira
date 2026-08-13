class CreateContentPages < ActiveRecord::Migration[8.1]
  def change
    create_table :content_pages do |t|
      t.integer :content_type, null: false
      t.string :title, null: false
      t.string :slug, null: false
      t.text :summary
      t.text :body
      t.references :taxonomy_tag, foreign_key: true
      t.boolean :show_find_service_cta, null: false, default: true
      t.boolean :show_chat_cta, null: false, default: true
      t.datetime :published_at

      t.timestamps
    end

    add_index :content_pages, :slug, unique: true
    add_index :content_pages, :content_type
  end
end
