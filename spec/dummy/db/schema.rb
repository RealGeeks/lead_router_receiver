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

ActiveRecord::Schema.define(version: 2018_05_02_210528) do

  create_table "lead_router_receiver_lead_router_messages", force: :cascade do |t|
    t.datetime "created"
    t.string "site_uuid"
    t.string "subject_id"
    t.string "action"
    t.text "body"
    t.string "processing_status", default: "new"
    t.text "processing_log"
    t.string "last_processing_message", limit: 100
    t.datetime "lead_router_timestamp"
    t.index ["site_uuid", "subject_id"], name: "index_lead_router_messages_on_site_uuid_and_subject_id"
    t.index ["subject_id", "lead_router_timestamp"], name: "index_lead_router_messages_on_subject_id_and_lr_timestamp"
    t.index ["subject_id"], name: "index_lead_router_messages_on_subject_id"
  end

end
