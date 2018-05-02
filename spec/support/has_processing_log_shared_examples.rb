module LeadRouterReceiver
  RSpec.shared_examples "HasProcessingLog" do
    # NOTE: this requires a :record let statement to provide access to a
    # new (unsaved, but valid) instance of the model being described.

    describe "HasProcessingLog functionality" do

      specify "precondition: let(:record) is valid" do
        expect( record ).to be_valid
      end

      specify "#success! sets processing_status and saves the record" do
        expect( record ).to_not be_persisted
        expect( record.processing_status ).to eq( "new" )

        record.success!

        expect( record ).to be_persisted
        expect( record.processing_status ).to eq( "success" )
      end

      specify "#failure! sets processing_status and saves the record" do
        expect( record ).to_not be_persisted
        expect( record.processing_status ).to eq( "new" )

        record.failure!

        expect( record ).to be_persisted
        expect( record.processing_status ).to eq( "failure" )
      end

      describe "#record_event" do
        let(:msg1) { "hello, world" }
        let(:msg2) { "and we're done here" }
        let(:t1) { Clock.as_of( 10.seconds.ago ) }
        let(:t2) { Clock.as_of(  5.seconds.ago ) }
        let(:t3) { Clock.as_of(  3.seconds.ago ) }

        it "appends messages onto the record, which can be accessed later via #processing_events" do
          record.record_event msg1, clock: t1
          record.record_event msg2, clock: t2

          events = record.processing_events
          expect( events.map(&:class).uniq ).to eq( [ HasProcessingLog::Event ] )
          expect( events.map(&:message)    ).to eq( [ msg1, msg2 ] )
          expect( events.map(&:time)       ).to eq( [ t1, t2 ].map(&:to_time) )
        end

        specify "#processing_events is persisted across AR instantiations" do
          record.record_event msg1, clock: t1
          record.record_event msg2, clock: t2

          record.save!
          lrm_prime = described_class.find(record.id)

          events = lrm_prime.processing_events
          expect( events.map(&:class).uniq ).to eq( [ HasProcessingLog::Event ] )
          expect( events.map(&:message)    ).to eq( [ msg1, msg2 ] )
          expect( events.map(&:time)       ).to eq( [ t1, t2 ].map(&:to_time) )
        end

        specify "[some of] the last event message is written to the #last_processing_message field" do
          expect( record.last_processing_message ).to be nil

          record.record_event msg1, clock: t1
          expect( record.last_processing_message ).to eq( msg1 )

          record.record_event msg2, clock: t2
          expect( record.last_processing_message ).to eq( msg2 )

          verse = [
            "this is the song that never ends",
            "it just goes on and on my friends",
            "some people started singin' it not knowin' what it was",
            "and they'll continue singin' it forever just because",
          ]
          song = (verse * 100).join(" / ")
          record.record_event song, clock: t3

          expect( record.last_processing_message ).to match( /^this is the song that never ends/ )
        end
      end

    end
  end
end
