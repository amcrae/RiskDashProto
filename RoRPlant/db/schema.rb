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

ActiveRecord::Schema[7.0].define(version: 2023_09_20_020918) do
  create_table "assets", force: :cascade do |t|
    t.string "uuid"
    t.string "shortname"
    t.string "asset_type"
    t.string "readiness"
    t.float "pof"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "m_locations", force: :cascade do |t|
    t.string "uuid"
    t.integer "segment_id", null: false
    t.string "shortname"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["segment_id"], name: "index_m_locations_on_segment_id"
  end

  create_table "measurements", force: :cascade do |t|
    t.string "uuid"
    t.integer "m_location_id", null: false
    t.datetime "timestamp"
    t.string "qtype"
    t.decimal "v", precision: 16, scale: 6
    t.string "uom"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["m_location_id"], name: "index_measurements_on_m_location_id"
  end

  create_table "segment_connections", force: :cascade do |t|
    t.string "uuid"
    t.string "shortname"
    t.string "segtype"
    t.integer "from_segment_id", null: false
    t.integer "to_segment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_segment_id"], name: "index_segment_connections_on_from_segment_id"
    t.index ["to_segment_id"], name: "index_segment_connections_on_to_segment_id"
  end

  create_table "segments", force: :cascade do |t|
    t.string "uuid"
    t.string "shortname"
    t.string "segtype"
    t.integer "parent_id"
    t.string "operational"
    t.integer "asset_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_segments_on_asset_id"
    t.index ["parent_id"], name: "index_segments_on_parent_id"
  end

  add_foreign_key "m_locations", "segments"
  add_foreign_key "measurements", "m_locations"
  add_foreign_key "segment_connections", "segments", column: "from_segment_id"
  add_foreign_key "segment_connections", "segments", column: "to_segment_id"
  add_foreign_key "segments", "assets"
  add_foreign_key "segments", "segments", column: "parent_id"
end
