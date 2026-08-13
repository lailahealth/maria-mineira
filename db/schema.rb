# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_13_143658) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "postgis"

  create_table "chat_conversations", force: :cascade do |t|
    t.string "context_tag"
    t.datetime "created_at", null: false
    t.uuid "journey_session_id", null: false
    t.bigint "municipality_id"
    t.bigint "service_category_id"
    t.integer "stage", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["journey_session_id"], name: "index_chat_conversations_on_journey_session_id"
    t.index ["municipality_id"], name: "index_chat_conversations_on_municipality_id"
    t.index ["service_category_id"], name: "index_chat_conversations_on_service_category_id"
  end

  create_table "chat_messages", force: :cascade do |t|
    t.text "body"
    t.integer "card_type"
    t.bigint "chat_conversation_id", null: false
    t.datetime "created_at", null: false
    t.integer "role", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_conversation_id"], name: "index_chat_messages_on_chat_conversation_id"
  end

  create_table "spatial_ref_sys", primary_key: "srid", id: :integer, default: nil, force: :cascade do |t|
    t.string "auth_name", limit: 256
    t.integer "auth_srid"
    t.string "proj4text", limit: 2048
    t.string "srtext", limit: 2048
    t.check_constraint "srid > 0 AND srid <= 998999", name: "spatial_ref_sys_srid_check"
  end

  create_table "taxonomy_tags", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.integer "kind", default: 0, null: false
    t.string "label", null: false
    t.bigint "parent_id"
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_taxonomy_tags_on_parent_id"
    t.index ["slug"], name: "index_taxonomy_tags_on_slug", unique: true
  end

# Could not dump table "territorial_facilities" because of following StandardError
#   Unknown type 'geography(Point,4326)' for column 'location'


  create_table "territorial_facility_service_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "facility_id", null: false
    t.bigint "service_category_id", null: false
    t.datetime "updated_at", null: false
    t.index ["facility_id", "service_category_id"], name: "index_facility_service_categories_uniqueness", unique: true
    t.index ["facility_id"], name: "index_territorial_facility_service_categories_on_facility_id"
    t.index ["service_category_id"], name: "idx_on_service_category_id_94c43e951f"
  end

  create_table "territorial_municipalities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ibge_code", null: false
    t.string "name", null: false
    t.string "region"
    t.string "state", default: "MG", null: false
    t.datetime "updated_at", null: false
    t.index ["ibge_code"], name: "index_territorial_municipalities_on_ibge_code", unique: true
    t.index ["name"], name: "index_territorial_municipalities_on_name"
  end

  create_table "territorial_service_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.bigint "taxonomy_tag_id"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_territorial_service_categories_on_slug", unique: true
    t.index ["taxonomy_tag_id"], name: "index_territorial_service_categories_on_taxonomy_tag_id"
  end

  add_foreign_key "chat_conversations", "territorial_municipalities", column: "municipality_id"
  add_foreign_key "chat_conversations", "territorial_service_categories", column: "service_category_id"
  add_foreign_key "chat_messages", "chat_conversations"
  add_foreign_key "taxonomy_tags", "taxonomy_tags", column: "parent_id"
  add_foreign_key "territorial_facilities", "territorial_municipalities", column: "municipality_id"
  add_foreign_key "territorial_facility_service_categories", "territorial_facilities", column: "facility_id"
  add_foreign_key "territorial_facility_service_categories", "territorial_service_categories", column: "service_category_id"
  add_foreign_key "territorial_service_categories", "taxonomy_tags"
end
