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

ActiveRecord::Schema[8.1].define(version: 2026_08_13_143657) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "journey_chat_turns", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "journey_session_id", null: false
    t.string "subtag_chat"
    t.string "tag_chat"
    t.index ["journey_session_id"], name: "index_journey_chat_turns_on_journey_session_id"
  end

  create_table "journey_events", force: :cascade do |t|
    t.string "categoria_servico"
    t.datetime "created_at", null: false
    t.float "distancia_aproximada_km"
    t.bigint "equipamento_indicado_id"
    t.string "equipamento_indicado_nome"
    t.integer "event_type", null: false
    t.uuid "journey_session_id", null: false
    t.string "municipality_ibge_code"
    t.integer "resultado"
    t.string "subtag"
    t.string "tag"
    t.index ["event_type"], name: "index_journey_events_on_event_type"
    t.index ["journey_session_id"], name: "index_journey_events_on_journey_session_id"
    t.index ["municipality_ibge_code"], name: "index_journey_events_on_municipality_ibge_code"
    t.index ["tag"], name: "index_journey_events_on_tag"
  end

  create_table "journey_sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "campanha"
    t.string "conteudo_origem"
    t.datetime "created_at", null: false
    t.string "device_hint"
    t.string "municipality_ibge_code"
    t.string "pagina_entrada"
    t.string "plataforma_origem"
    t.datetime "started_at", null: false
    t.string "subtag_origem"
    t.string "tag_origem"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "journey_chat_turns", "journey_sessions"
  add_foreign_key "journey_events", "journey_sessions"
end
