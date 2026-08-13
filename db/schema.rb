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

ActiveRecord::Schema[8.1].define(version: 2026_08_13_181646) do
  create_schema "tiger"
  create_schema "topology"

  # These are extensions that must be enabled in order to support this database
  enable_extension "fuzzystrmatch"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "postgis"
  enable_extension "tiger.postgis_tiger_geocoder"
  enable_extension "topology.postgis_topology"

  create_table "public.active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "public.active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "public.active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "public.chat_conversations", force: :cascade do |t|
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

  create_table "public.chat_messages", force: :cascade do |t|
    t.text "body"
    t.integer "card_type"
    t.bigint "chat_conversation_id", null: false
    t.datetime "created_at", null: false
    t.integer "role", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_conversation_id"], name: "index_chat_messages_on_chat_conversation_id"
  end

  create_table "public.content_pages", force: :cascade do |t|
    t.text "body"
    t.integer "content_type", null: false
    t.datetime "created_at", null: false
    t.datetime "published_at"
    t.boolean "show_chat_cta", default: true, null: false
    t.boolean "show_find_service_cta", default: true, null: false
    t.string "slug", null: false
    t.text "summary"
    t.bigint "taxonomy_tag_id"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["content_type"], name: "index_content_pages_on_content_type"
    t.index ["slug"], name: "index_content_pages_on_slug", unique: true
    t.index ["taxonomy_tag_id"], name: "index_content_pages_on_taxonomy_tag_id"
  end

  create_table "public.partners_partners", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "coverage_scope"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "partner_type", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["active"], name: "index_partners_partners_on_active"
    t.index ["partner_type"], name: "index_partners_partners_on_partner_type"
  end

  create_table "public.spatial_ref_sys", primary_key: "srid", id: :integer, default: nil, force: :cascade do |t|
    t.string "auth_name", limit: 256
    t.integer "auth_srid"
    t.string "proj4text", limit: 2048
    t.string "srtext", limit: 2048
    t.check_constraint "srid > 0 AND srid <= 998999", name: "spatial_ref_sys_srid_check"
  end

  create_table "public.taxonomy_tags", force: :cascade do |t|
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


  create_table "public.territorial_facility_service_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "facility_id", null: false
    t.bigint "service_category_id", null: false
    t.datetime "updated_at", null: false
    t.index ["facility_id", "service_category_id"], name: "index_facility_service_categories_uniqueness", unique: true
    t.index ["facility_id"], name: "index_territorial_facility_service_categories_on_facility_id"
    t.index ["service_category_id"], name: "idx_on_service_category_id_94c43e951f"
  end

  create_table "public.territorial_municipalities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ibge_code", null: false
    t.string "name", null: false
    t.string "region"
    t.string "state", default: "MG", null: false
    t.datetime "updated_at", null: false
    t.index ["ibge_code"], name: "index_territorial_municipalities_on_ibge_code", unique: true
    t.index ["name"], name: "index_territorial_municipalities_on_name"
  end

  create_table "public.territorial_service_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.bigint "taxonomy_tag_id"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_territorial_service_categories_on_slug", unique: true
    t.index ["taxonomy_tag_id"], name: "index_territorial_service_categories_on_taxonomy_tag_id"
  end

  add_foreign_key "public.active_storage_attachments", "public.active_storage_blobs", column: "blob_id"
  add_foreign_key "public.active_storage_variant_records", "public.active_storage_blobs", column: "blob_id"
  add_foreign_key "public.chat_conversations", "public.territorial_municipalities", column: "municipality_id"
  add_foreign_key "public.chat_conversations", "public.territorial_service_categories", column: "service_category_id"
  add_foreign_key "public.chat_messages", "public.chat_conversations"
  add_foreign_key "public.content_pages", "public.taxonomy_tags"
  add_foreign_key "public.taxonomy_tags", "public.taxonomy_tags", column: "parent_id"
  add_foreign_key "public.territorial_facilities", "public.territorial_municipalities", column: "municipality_id"
  add_foreign_key "public.territorial_facility_service_categories", "public.territorial_facilities", column: "facility_id"
  add_foreign_key "public.territorial_facility_service_categories", "public.territorial_service_categories", column: "service_category_id"
  add_foreign_key "public.territorial_service_categories", "public.taxonomy_tags"

  create_table "topology.layer", primary_key: ["topology_id", "layer_id"], force: :cascade do |t|
    t.integer "child_id"
    t.string "feature_column", null: false
    t.integer "feature_type", null: false
    t.integer "layer_id", null: false
    t.integer "level", default: 0, null: false
    t.string "schema_name", null: false
    t.string "table_name", null: false
    t.integer "topology_id", null: false

    t.unique_constraint ["schema_name", "table_name", "feature_column"], name: "layer_schema_name_table_name_feature_column_key"
  end

  create_table "topology.topology", id: :serial, force: :cascade do |t|
    t.boolean "hasz", default: false, null: false
    t.string "name", null: false
    t.float "precision", null: false
    t.integer "srid", null: false

    t.unique_constraint ["name"], name: "topology_name_key"
  end

  add_foreign_key "topology.layer", "topology.topology", name: "layer_topology_id_fkey"

  create_table "tiger.addr", primary_key: "gid", id: :serial, force: :cascade do |t|
    t.string "arid", limit: 22
    t.integer "fromarmid"
    t.string "fromhn", limit: 12
    t.string "fromtyp", limit: 1
    t.string "mtfcc", limit: 5
    t.string "plus4", limit: 4
    t.string "side", limit: 1
    t.string "statefp", limit: 2
    t.bigint "tlid"
    t.integer "toarmid"
    t.string "tohn", limit: 12
    t.string "totyp", limit: 1
    t.string "zip", limit: 5
    t.index ["tlid", "statefp"], name: "idx_tiger_addr_tlid_statefp"
    t.index ["zip"], name: "idx_tiger_addr_zip"
  end

# Could not dump table "addrfeat" because of following StandardError
#   Unknown type 'public.geometry' for column 'the_geom'


# Could not dump table "bg" because of following StandardError
#   Unknown type 'public.geometry' for column 'the_geom'


# Could not dump table "county" because of following StandardError
#   Unknown type 'public.geometry' for column 'the_geom'


  create_table "tiger.county_lookup", primary_key: ["st_code", "co_code"], force: :cascade do |t|
    t.integer "co_code", null: false
    t.string "name", limit: 90
    t.integer "st_code", null: false
    t.string "state", limit: 2
    t.index "public.soundex((name)::text)", name: "county_lookup_name_idx"
    t.index ["state"], name: "county_lookup_state_idx"
  end

  create_table "tiger.countysub_lookup", primary_key: ["st_code", "co_code", "cs_code"], force: :cascade do |t|
    t.integer "co_code", null: false
    t.string "county", limit: 90
    t.integer "cs_code", null: false
    t.string "name", limit: 90
    t.integer "st_code", null: false
    t.string "state", limit: 2
    t.index "public.soundex((name)::text)", name: "countysub_lookup_name_idx"
    t.index ["state"], name: "countysub_lookup_state_idx"
  end

# Could not dump table "cousub" because of following StandardError
#   Unknown type 'public.geometry' for column 'the_geom'


  create_table "tiger.direction_lookup", primary_key: "name", id: { type: :string, limit: 20 }, force: :cascade do |t|
    t.string "abbrev", limit: 3
    t.index ["abbrev"], name: "direction_lookup_abbrev_idx"
  end

# Could not dump table "edges" because of following StandardError
#   Unknown type 'public.geometry' for column 'the_geom'


# Could not dump table "faces" because of following StandardError
#   Unknown type 'public.geometry' for column 'the_geom'


  create_table "tiger.featnames", primary_key: "gid", id: :serial, force: :cascade do |t|
    t.string "fullname", limit: 100
    t.string "linearid", limit: 22
    t.string "mtfcc", limit: 5
    t.string "name", limit: 100
    t.string "paflag", limit: 1
    t.string "predir", limit: 2
    t.string "predirabrv", limit: 15
    t.string "prequal", limit: 2
    t.string "prequalabr", limit: 15
    t.string "pretyp", limit: 3
    t.string "pretypabrv", limit: 50
    t.string "statefp", limit: 2
    t.string "sufdir", limit: 2
    t.string "sufdirabrv", limit: 15
    t.string "sufqual", limit: 2
    t.string "sufqualabr", limit: 15
    t.string "suftyp", limit: 3
    t.string "suftypabrv", limit: 50
    t.bigint "tlid"
    t.index "lower((name)::text)", name: "idx_tiger_featnames_lname"
    t.index "public.soundex((name)::text)", name: "idx_tiger_featnames_snd_name"
    t.index ["tlid", "statefp"], name: "idx_tiger_featnames_tlid_statefp"
  end

  create_table "tiger.geocode_settings", primary_key: "name", id: :text, force: :cascade do |t|
    t.text "category"
    t.text "setting"
    t.text "short_desc"
    t.text "unit"
  end

  create_table "tiger.geocode_settings_default", primary_key: "name", id: :text, force: :cascade do |t|
    t.text "category"
    t.text "setting"
    t.text "short_desc"
    t.text "unit"
  end

  create_table "tiger.loader_lookuptables", primary_key: "lookup_name", id: { type: :text, comment: "This is the table name to inherit from and suffix of resulting output table -- how the table will be named --  edges here would mean -- ma_edges , pa_edges etc. except in the case of national tables. national level tables have no prefix" }, force: :cascade do |t|
    t.text "columns_exclude", comment: "List of columns to exclude as an array. This is excluded from both input table and output table and rest of columns remaining are assumed to be in same order in both tables. gid, geoid,cpi,suffix1ce are excluded if no columns are specified.", array: true
    t.string "insert_mode", limit: 1, default: "c", null: false
    t.boolean "level_county", default: false, null: false
    t.boolean "level_nation", default: false, null: false, comment: "These are tables that contain all data for the whole US so there is just a single file"
    t.boolean "level_state", default: false, null: false
    t.boolean "load", default: true, null: false, comment: "Whether or not to load the table.  For states and zcta5 (you may just want to download states10, zcta510 nationwide file manually) load your own into a single table that inherits from tiger.states, tiger.zcta5.  You'll get improved performance for some geocoding cases."
    t.text "post_load_process"
    t.text "pre_load_process"
    t.integer "process_order", default: 1000, null: false
    t.boolean "single_geom_mode", default: false
    t.boolean "single_mode", default: true, null: false
    t.text "table_name", comment: "suffix of the tables to load e.g.  edges would load all tables like *edges.dbf(shp)  -- so tl_2010_42129_edges.dbf .  "
    t.text "website_root_override", comment: "Path to use for wget instead of that specified in year table.  Needed currently for zcta where they release that only for 2000 and 2010"
  end

  create_table "tiger.loader_platform", primary_key: "os", id: { type: :string, limit: 50 }, force: :cascade do |t|
    t.text "county_process_command"
    t.text "declare_sect"
    t.text "environ_set_command"
    t.text "loader"
    t.text "path_sep"
    t.text "pgbin"
    t.text "psql"
    t.text "unzip_command"
    t.text "wget"
  end

  create_table "tiger.loader_variables", primary_key: "tiger_year", id: { type: :string, limit: 4 }, force: :cascade do |t|
    t.text "data_schema"
    t.text "staging_fold"
    t.text "staging_schema"
    t.text "website_root"
  end

  create_table "tiger.pagc_gaz", id: :serial, force: :cascade do |t|
    t.boolean "is_custom", default: true, null: false
    t.integer "seq"
    t.text "stdword"
    t.integer "token"
    t.text "word"
  end

  create_table "tiger.pagc_lex", id: :serial, force: :cascade do |t|
    t.boolean "is_custom", default: true, null: false
    t.integer "seq"
    t.text "stdword"
    t.integer "token"
    t.text "word"
  end

  create_table "tiger.pagc_rules", id: :serial, force: :cascade do |t|
    t.boolean "is_custom", default: true
    t.text "rule"
  end

# Could not dump table "place" because of following StandardError
#   Unknown type 'public.geometry' for column 'the_geom'


  create_table "tiger.place_lookup", primary_key: ["st_code", "pl_code"], force: :cascade do |t|
    t.string "name", limit: 90
    t.integer "pl_code", null: false
    t.integer "st_code", null: false
    t.string "state", limit: 2
    t.index "public.soundex((name)::text)", name: "place_lookup_name_idx"
    t.index ["state"], name: "place_lookup_state_idx"
  end

  create_table "tiger.secondary_unit_lookup", primary_key: "name", id: { type: :string, limit: 20 }, force: :cascade do |t|
    t.string "abbrev", limit: 5
    t.index ["abbrev"], name: "secondary_unit_lookup_abbrev_idx"
  end

# Could not dump table "state" because of following StandardError
#   Unknown type 'public.geometry' for column 'the_geom'


  create_table "tiger.state_lookup", primary_key: "st_code", id: :integer, default: nil, force: :cascade do |t|
    t.string "abbrev", limit: 3
    t.string "name", limit: 40
    t.string "statefp", limit: 2

    t.unique_constraint ["abbrev"], name: "state_lookup_abbrev_key"
    t.unique_constraint ["name"], name: "state_lookup_name_key"
    t.unique_constraint ["statefp"], name: "state_lookup_statefp_key"
  end

  create_table "tiger.street_type_lookup", primary_key: "name", id: { type: :string, limit: 50 }, force: :cascade do |t|
    t.string "abbrev", limit: 50
    t.boolean "is_hw", default: false, null: false
    t.index ["abbrev"], name: "street_type_lookup_abbrev_idx"
  end

# Could not dump table "tabblock" because of following StandardError
#   Unknown type 'public.geometry' for column 'the_geom'


# Could not dump table "tabblock20" because of following StandardError
#   Unknown type 'public.geometry(MultiPolygon,4269)' for column 'the_geom'


# Could not dump table "tract" because of following StandardError
#   Unknown type 'public.geometry' for column 'the_geom'


# Could not dump table "zcta5" because of following StandardError
#   Unknown type 'public.geometry' for column 'the_geom'


  create_table "tiger.zip_lookup", primary_key: "zip", id: :integer, default: nil, force: :cascade do |t|
    t.integer "cnt"
    t.integer "co_code"
    t.string "county", limit: 90
    t.string "cousub", limit: 90
    t.integer "cs_code"
    t.integer "pl_code"
    t.string "place", limit: 90
    t.integer "st_code"
    t.string "state", limit: 2
  end

  create_table "tiger.zip_lookup_all", id: false, force: :cascade do |t|
    t.integer "cnt"
    t.integer "co_code"
    t.string "county", limit: 90
    t.string "cousub", limit: 90
    t.integer "cs_code"
    t.integer "pl_code"
    t.string "place", limit: 90
    t.integer "st_code"
    t.string "state", limit: 2
    t.integer "zip"
  end

  create_table "tiger.zip_lookup_base", primary_key: "zip", id: { type: :string, limit: 5 }, force: :cascade do |t|
    t.string "city", limit: 90
    t.string "county", limit: 90
    t.string "state", limit: 40
    t.string "statefp", limit: 2
  end

  create_table "tiger.zip_state", primary_key: ["zip", "stusps"], force: :cascade do |t|
    t.string "statefp", limit: 2
    t.string "stusps", limit: 2, null: false
    t.string "zip", limit: 5, null: false
  end

  create_table "tiger.zip_state_loc", primary_key: ["zip", "stusps", "place"], force: :cascade do |t|
    t.string "place", limit: 100, null: false
    t.string "statefp", limit: 2
    t.string "stusps", limit: 2, null: false
    t.string "zip", limit: 5, null: false
  end
end
