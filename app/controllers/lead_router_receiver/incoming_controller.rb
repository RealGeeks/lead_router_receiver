require_dependency "lead_router_receiver/application_controller"

module LeadRouterReceiver
  class IncomingController < ApplicationController
    before_action :authenticate

    def receive_message
      render_status 406 and return unless in_actions_we_use?(lrm_action)
      render_status 406 and return unless adds_activities_we_care_about?

      message = create_message
      if message.persisted?
        enqueue_processor(message)
        render_status 200
      else
        raise "Unable to create LeadRouterMessage: #{message&.errors&.to_json}"
        render_status 500
      end
    end

    private

    def render_status(status)
      render body: nil, status: status
    end

    def authenticate
      return if ENV["DO_NOT_VERIFY_HMAC"] == "yes-really"

      text       = request.raw_post
      signature  = request.headers['HTTP_X_LEAD_ROUTER_SIGNATURE']
      env_secret = 'LEAD_ROUTER_SECRET'

      secret = ENV[env_secret]
      if secret.blank?
        Rails.logger.warn "[lead_router_receiver/authenticate]: Received a message that might be from Lead Router, but can't authenticate it without the #{env_secret} environment variable!"
        render_status 500
        return
      end

      unless valid_signature?( text, secret, signature )
        Rails.logger.warn "[lead_router_receiver/authenticate]: Received a message, but the signature doesn't match what we expected based on the #{env_secret} environment variable"
        render_status 404
      end

      # We now return you to your regularly scheduled
      # before_action lineup.
    end

    def valid_signature?( text, secret, provided_signature )
      expected_signature = sign_message( text, secret )
      provided_signature == expected_signature
    end

    def sign_message(text, secret)
      digest = OpenSSL::Digest.new('sha256')
      OpenSSL::HMAC.hexdigest(digest, secret, text)
    end

    def lrm_action
      @_lrm_action ||= ( header_action || json_data["action"] )
    end

    def header_action
      request.headers["X-Lead-Router-Action"]
    end

    def json_data
      @_json_data ||= JSON.parse(request.raw_post)
    end

    def create_message
      LeadRouterMessage.create({
        created:               header_timestamp || json_data["created"],
        site_uuid:             json_data["site_uuid"],
        action:                lrm_action,
        subject_id:            json_data["id"].gsub('-',''),
        body:                  request.raw_post,
        lead_router_timestamp: header_timestamp,
      })
    end

    def header_timestamp
      request.headers["X-Lead-Router-Timestamp"]
    end

    def adds_activities_we_care_about?
      return true if lrm_action != 'activity_added'

      activity_types = Array( json_data["activities"] ).map { |a| a['type'] }
      return false if activity_types.empty?

      results = activity_types.map do |activity_type|
        in_activity_types_we_use?(activity_type)
      end
      results.uniq != [false]
    end


    ##### METHODS THAT MOUNTING RAILS APP MUST OVERRIDE #####
    def in_actions_we_use?(*)
      fail NotImplementedError, __implement_me_message__("in_actions_we_use?(action)")
    end

    def in_activity_types_we_use?(*)
      fail NotImplementedError, __implement_me_message__("in_activity_types_we_use?(activity_type)")
    end

    def enqueue_processor(*)
      fail NotImplementedError, __implement_me_message__("enqueue_processor(message)")
    end
    ##### /METHODS THAT MOUNTING RAILS APP MUST OVERRIDE #####


    def __implement_me_message__(method_name_and_args)
      <<~EOF
        The Rails app that uses this engine MUST override this method!

        To do so, create a file "app/decorators/controllers/lead_router_receiver/incoming_controller_decorator.rb"
        and paste in the following code:

        ```
        LeadRouterReceiver::IncomingController.class_eval do
          def #{method_name_and_args}
            fail "write me"
          end
        end
        ```

        (...and, obviously, change the method body.)
      EOF
    end
  end
end
