class CreateLeadRouterReceiverLeadRouterMessages < ActiveRecord::Migration[5.2]
  def change
    create_table "lead_router_messages" do |t|
      t.datetime "created"
      t.string   "site_uuid"
      t.string   "subject_id"
      t.string   "action"
      t.text     "body"
      t.string   "processing_status", default: "new"
      t.text     "processing_log"
      t.string   "last_processing_message", limit: 100
      t.datetime "lead_router_timestamp"
    end

    add_index "lead_router_messages", ["site_uuid", "subject_id"], name: "index_lead_router_messages_on_site_uuid_and_subject_id", using: :btree
    add_index "lead_router_messages", ["subject_id", "lead_router_timestamp"], name: "index_lead_router_messages_on_subject_id_and_lr_timestamp", using: :btree
    add_index "lead_router_messages", ["subject_id"], name: "index_lead_router_messages_on_subject_id", using: :btree
  end
end
