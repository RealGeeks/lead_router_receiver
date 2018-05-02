require 'rails_helper'

module LeadRouterReceiver
  RSpec.describe IncomingController, type: :request do
    let(:incoming_path) { "/lead_router_receiver/incoming" }

    let(:site_uuid) { "5ead6dd1-2cb9-4f80-80fc-5716b05c90ba" }

    let(:json_body) { read_fixture_file( "lead_router/new_lead.json" ) }
    let(:header_timestamp) { "2016-12-24T01:58:52.789337607Z" }
    let(:headers) { {
      "CONTENT_TYPE"            => "application/json",
      "X-Lead-Router-Signature" => read_fixture_file( "lead_router/new_lead.signature" ),
      "X-Lead-Router-Timestamp" => header_timestamp,
    } }

    specify "nothing works without a LEAD_ROUTER_SECRET environment variable" do
      ClimateControl.modify LEAD_ROUTER_SECRET: nil do
        expect { post incoming_path, params: json_body, headers: headers }
          .to_not change { LeadRouterMessage.count }
        expect( response.status ).to eq( 500 )
      end
    end

    context "when LEAD_ROUTER_SECRET is present in the environment" do
      around :example do |example|
        ClimateControl.modify LEAD_ROUTER_SECRET: "seekrit" do
          example.run
        end
      end

      specify "when a message comes in, we save it as a LeadRouterMessage" do
        expect {
          post incoming_path, params: json_body, headers: headers
        }.to change { LeadRouterMessage.count }.by(1)

        expect( response.status ).to eq( 200 )
      end

      describe "the created LRM" do
        subject(:lrm) { LeadRouterMessage.last }

        before do
          post incoming_path, params: json_body, headers: headers
        end

        ONE_MICROSECOND = 0.000_001

        its( :lead_router_timestamp ) {
          is_expected.to be_within( ONE_MICROSECOND ).of( Time.zone.parse(header_timestamp) )
        }

        its( :body              ) { is_expected.to eq( json_body ) }
        its( :created           ) { is_expected.to eq( lrm.lead_router_timestamp ) }
        its( :processing_status ) { is_expected.to eq( "new" )                     }
        its( :site_uuid         ) { is_expected.to eq( site_uuid )                 }
      end

      specify "ignore lead router messages for actions we do not care about" do
        pending "configurable options"

        headers["X-Lead-Router-Action"] = "magic"
        post incoming_path, params: json_body, headers: headers
        expect( LeadRouterMessage.count ).to eq( 0 )
      end

      specify "ignore this unrelated lead router message" do
        pending "configurable options"

        headers["X-Lead-Router-Action"] = "activity_added"
        post incoming_path, params: json_body, headers: headers
        expect( LeadRouterMessage.count ).to eq( 0 )
      end

      specify "the action from the header overrides the 'action' value in the JSON" do
        headers["X-Lead-Router-Action"] = "updated"
        post incoming_path, params: json_body, headers: headers
        lrm = LeadRouterMessage.last
        expect( lrm.action ).to eq( "updated" )
      end

      specify "after the message is saved, we enqueue a job to process it" do
        pending "configurable options"

        post "/v1/lead_router", params: json_body, headers: headers
        message = LeadRouterMessage.last

        expect( ProcessLeadRouterMessagesForSubject ).to have_received( :perform_async ).with( message.subject_id, message.site_uuid )
      end

    end

  end
end
