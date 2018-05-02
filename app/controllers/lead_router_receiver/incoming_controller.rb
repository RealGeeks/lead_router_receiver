require_dependency "lead_router_receiver/application_controller"

module LeadRouterReceiver
  class IncomingController < ApplicationController
    before_action :authenticate

    def receive_message
      message = create_message
      if message && message.persisted?
        # enqueue_processor(message)# FIXME: figure out how to make this configurable
        render_status 200
      elsif message == false #Silently accept activities we do not care about
        render_status 406
      else
        raise "Unable to create LeadRouterMessage: #{message&.errors&.to_json}"
        render_status 500
      end
    end

    private

    def authenticate
      validate_rg_signature(
        text:       request.raw_post,
        signature:  request.headers['HTTP_X_LEAD_ROUTER_SIGNATURE'],
        env_secret: 'LEAD_ROUTER_SECRET',
      )
    end

    def validate_rg_signature( text:, signature:, env_secret: )
      secret = ENV[env_secret]

      if secret.blank?
        render_status 500
        return
      end

      unless valid_signature?( text, secret, signature )
        render_status 404
      end

      # We now return you to your regularly scheduled
      # before_action lineup.
    end

    def sign_message(text, secret)
      digest = OpenSSL::Digest.new('sha256')
      OpenSSL::HMAC.hexdigest(digest, secret, text)
    end

    def valid_signature?( text, secret, provided_signature )
      expected_signature = sign_message( text, secret )
      provided_signature == expected_signature
    end

    def create_message
      raw_json = request.raw_post
      json_data = JSON.parse(raw_json)
      action = header_action || json_data["action"]
      # return false unless in_actions_we_use?(action)                                   # FIXME: figure out how to make this configurable
      # return false if action == 'activity_added' && !any_activities_we_use?(json_data) # FIXME: figure out how to make this configurable

      lrm = LeadRouterMessage.create({
        created:               header_timestamp || json_data["created"],
        site_uuid:             json_data["site_uuid"],
        action:                action,
        subject_id:            json_data["id"].gsub('-',''),
        body:                  raw_json,
        lead_router_timestamp: header_timestamp,
      })
      lrm
    end

    def header_timestamp ; request.headers["X-Lead-Router-Timestamp"] ; end
    def header_action    ; request.headers["X-Lead-Router-Action"]    ; end

    def render_status(status)
      render body: nil, status: status
    end
  end
end
