module LeadRouterReceiver
  class LeadRouterMessage < ApplicationRecord
    include HasProcessingLog

    def self.ignored_after ;  7.days ; end
    def self.deleted_after ; 14.days ; end

    scope :for_subject_id, ->(subject_id) { where(subject_id: subject_id) }

    scope :not_stale, ->(clock:) { where([ "lead_router_timestamp > ?", clock.minus( ignored_after ).to_time ]) }
    scope :expired,   ->(clock:) { where([ "lead_router_timestamp < ?", clock.minus( deleted_after ).to_time ]) }

    def self.create_from_json(raw_json, json_data = nil)
      new_from_json(raw_json, json_data).tap do |lrm|
        lrm.save
      end
    end

    def self.new_from_json(raw_json, json_data = nil)
      json_data ||= JSON.parse(raw_json)
      new({
        created:               json_data["created"],
        lead_router_timestamp: json_data["created"],
        site_uuid:             json_data["site_uuid"],
        action:                json_data["action"],
        subject_id:            json_data["id"],
        body:                  raw_json,
      })
    end


    def parsed_data
      @parsed_data ||= JSON.parse(body)
    end
  end
end
