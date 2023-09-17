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

ActiveRecord::Schema[7.0].define(version: 2023_09_17_062504) do
  create_table "assets", force: :cascade do |t|
    t.string "uuid"
    t.string "shortname"
    t.string "asset_type"
    t.string "readiness"
    t.float "pof"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.integer "mlocation_id", null: false
    t.datetime "timestamp"
    t.string "qtype"
    t.decimal "v", precision: 16, scale: 6
    t.string "uom"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mlocation_id"], name: "index_measurements_on_mlocation_id"
  end

  create_table "segment_connections", force: :cascade do |t|
    t.string "uuid"
    t.string "shortname"
    t.string "segtype"
    t.integer "from_segment"
    t.integer "to_segment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "segments", force: :cascade do |t|
    t.string "uuid"
    t.string "shortname"
    t.string "segtype"
    t.integer "segment_id", null: false
    t.string "operational"
    t.integer "asset_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_segments_on_asset_id"
    t.index ["segment_id"], name: "index_segments_on_segment_id"
  end

  add_foreign_key "m_locations", "segments"
  add_foreign_key "measurements", "mlocations"
  add_foreign_key "segments", "assets"
  add_foreign_key "segments", "segments"
end