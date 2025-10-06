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

ActiveRecord::Schema[8.0].define(version: 2025_10_06_003733) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "submissions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "leetcode_id", null: false
    t.string "title", null: false
    t.string "title_slug", null: false
    t.string "status", null: false
    t.string "language", null: false
    t.bigint "timestamp", null: false
    t.string "url", null: false
    t.text "code"
    t.datetime "submitted_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["submitted_at"], name: "index_submissions_on_submitted_at"
    t.index ["user_id", "language"], name: "index_submissions_on_user_id_and_language"
    t.index ["user_id", "leetcode_id"], name: "index_submissions_on_user_id_and_leetcode_id", unique: true
    t.index ["user_id", "status"], name: "index_submissions_on_user_id_and_status"
    t.index ["user_id", "submitted_at"], name: "index_submissions_on_user_id_and_submitted_at", order: { submitted_at: :desc }
    t.index ["user_id"], name: "index_submissions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "leetcode_username"
    t.text "leetcode_cookies"
    t.datetime "leetcode_last_sync"
    t.integer "leetcode_solved_count"
    t.integer "leetcode_total_count"
    t.integer "leetcode_rank"
    t.text "leetcode_notes"
    t.text "recent_submissions"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["leetcode_username"], name: "index_users_on_leetcode_username", unique: true, where: "(leetcode_username IS NOT NULL)"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "submissions", "users"
end
