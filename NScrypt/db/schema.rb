# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150221091251) do

# Could not dump table "codes" because of following NoMethodError
#   undefined method `[]' for nil:NilClass

# Could not dump table "contracts" because of following NoMethodError
#   undefined method `[]' for nil:NilClass

  create_table "create_wallets", force: :cascade do |t|
    t.string   "currency"
    t.string   "address"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "create_wallets", ["user_id"], name: "index_create_wallets_on_user_id"

  create_table "notes", force: :cascade do |t|
    t.string   "note"
    t.integer  "contract_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "notes", ["contract_id"], name: "index_notes_on_contract_id"

  create_table "parties", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "code_id"
    t.integer  "role_id"
    t.string   "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "parties", ["code_id"], name: "index_parties_on_code_id"
  add_index "parties", ["role_id"], name: "index_parties_on_role_id"
  add_index "parties", ["user_id"], name: "index_parties_on_user_id"

  create_table "roles", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sc_event_runs", force: :cascade do |t|
    t.integer  "sc_event_id"
    t.datetime "run_at"
    t.string   "result"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "sc_event_runs", ["sc_event_id"], name: "index_sc_event_runs_on_sc_event_id"

  create_table "sc_events", force: :cascade do |t|
    t.text     "callback"
    t.integer  "code_id",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "sc_events", ["code_id"], name: "index_sc_events_on_code_id"

  create_table "sc_values", force: :cascade do |t|
    t.integer  "contract_id"
    t.string   "key"
    t.string   "value"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "sc_values", ["contract_id"], name: "index_sc_values_on_contract_id"

  create_table "schedules", force: :cascade do |t|
    t.integer  "sc_event_id", null: false
    t.datetime "timestamp"
    t.string   "argument"
    t.boolean  "recurrent"
    t.string   "status"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "schedules", ["sc_event_id"], name: "index_schedules_on_sc_event_id"

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.string   "password_hash"
    t.string   "password_salt"
    t.string   "type"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

end
