require 'rails_helper'

module LeadRouterReceiver
  RSpec.describe LeadRouterMessage, type: :model do
    subject(:lrm) { described_class.new_from_json(raw_json) }

    let(:action) { "created" }
    let(:created) { "2016-07-27T22:27:04Z" }
    let(:site_uuid) { "42cc1d70-c912-11e0-8a75-001cc45fad02" }

    let(:raw_json) {
      # Irrelevant attributes have been omitted for brevity
      <<-JSON.strip
{
  "action": "#{action}",
  "created": "#{created}",
  "site_uuid": "#{site_uuid}",
  "id": "a35d03c4115c4b0dbf5f27b404dc4264",
  "first_name": "Leady",
  "last_name": "McLeaderson",
  "source_system": "LeadManager"
}
      JSON
    }
    let(:json_data) { JSON.parse(raw_json) }

    describe ".create_from_json" do
      subject(:lrm) { described_class.create_from_json(raw_json) }

      it "creates a record" do
        expect( lrm ).to be_persisted
      end

      it "extracts the 'action' JSON field, writing it to the record's #action DB field" do
        expect( json_data["action"] ).to be_present
        expect( lrm.action ).to eq( json_data["action"] )
      end

      it "extracts the 'site_uuid' JSON field, writing it to the record's #site_uuid DB field" do
        expect( json_data["site_uuid"] ).to be_present
        expect( lrm.site_uuid ).to eq( json_data["site_uuid"] )
      end

      it "extracts the 'created' JSON field, writing it to the record's #created DB field" do
        expect( json_data["created"] ).to be_present
        expect( lrm.created ).to eq( json_data["created"] )
      end

      it "extracts the 'id' JSON field, writing it to the record's #subject_id DB field" do
        expect( json_data["id"] ).to be_present
        expect( lrm.subject_id ).to eq( json_data["id"] )
      end

      it "writes the raw json to its #body field" do
        expect( lrm.body ).to eq( raw_json )
      end
    end

    describe "#parsed_data" do
      it "parses the body as JSON" do
        lrm = described_class.new(body: raw_json)
        expect( lrm.parsed_data ).to eq( json_data )
      end
    end

    specify "record_event should save log info" do
      expect( lrm.processing_log.empty? ).to eq( true )
      lrm.record_event "foo"
      expect( lrm.processing_log.empty? ).to eq( false )
    end

    include_examples "HasProcessingLog" do
      let(:record) { described_class.new }
    end
  end
end
