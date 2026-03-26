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

ActiveRecord::Schema[8.1].define(version: 2026_02_24_010646) do
  create_table "circle_snapshots", force: :cascade do |t|
    t.integer "circle_id", null: false
    t.datetime "created_at", null: false
    t.text "snapshot_data"
    t.datetime "updated_at", null: false
    t.integer "version"
    t.index ["circle_id"], name: "index_circle_snapshots_on_circle_id"
  end

  create_table "circles", force: :cascade do |t|
    t.string "color_theme"
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "is_public"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "version"
    t.index ["user_id"], name: "index_circles_on_user_id"
  end

  create_table "connections", force: :cascade do |t|
    t.integer "connection_type"
    t.datetime "created_at", null: false
    t.integer "from_user_id", null: false
    t.integer "status"
    t.integer "to_user_id", null: false
    t.datetime "updated_at", null: false
    t.index ["from_user_id"], name: "index_connections_on_from_user_id"
    t.index ["to_user_id"], name: "index_connections_on_to_user_id"
  end

  create_table "radians", force: :cascade do |t|
    t.integer "circle_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.boolean "is_archived"
    t.float "position_angle"
    t.datetime "updated_at", null: false
    t.index ["circle_id"], name: "index_radians_on_circle_id"
  end

  create_table "shares", force: :cascade do |t|
    t.integer "circle_id", null: false
    t.datetime "created_at", null: false
    t.integer "permission_level"
    t.integer "shared_by_user_id", null: false
    t.integer "shared_with_user_id", null: false
    t.datetime "updated_at", null: false
    t.index ["circle_id"], name: "index_shares_on_circle_id"
    t.index ["shared_by_user_id"], name: "index_shares_on_shared_by_user_id"
    t.index ["shared_with_user_id"], name: "index_shares_on_shared_with_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.string "password_digest"
    t.integer "profile_visibility"
    t.datetime "updated_at", null: false
    t.string "username"
  end

  add_foreign_key "circle_snapshots", "circles"
  add_foreign_key "circles", "users"
  add_foreign_key "connections", "from_users"
  add_foreign_key "connections", "to_users"
  add_foreign_key "radians", "circles"
  add_foreign_key "shares", "circles"
  add_foreign_key "shares", "shared_by_users"
  add_foreign_key "shares", "shared_with_users"
end
