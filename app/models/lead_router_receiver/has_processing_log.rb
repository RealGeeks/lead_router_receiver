# This provides behavior related to the :processing_log,
# :processing_status, and :last_processing_message columns.
#
# This behavior was originally on LeadRouterMessage and has been
# extracted here to make it easier to reuse.
module HasProcessingLog
  REQUIRED_COLUMN_NAMES = %w[ processing_log processing_status last_processing_message ]

  Event = Struct.new(:message, :time)

  module InstanceMethods
    def record_status(status)
      self.processing_status = status.to_s
    end

    def success! ; record_status "success" ; save! ; end
    def failure! ; record_status "failure" ; save! ; end
    def error!   ; record_status "error"   ; save! ; end

    def record_event(message, clock: Clock.for_current_time)
      cache_event_message message
      self.processing_log ||= Array.new
      event = HasProcessingLog::Event.new( message, clock.to_time )
      self.processing_log << event.to_a
    end

    def processing_events
      Array(processing_log).map { |event|
        HasProcessingLog::Event.new( *Array(event) )
      }
    end

    def processing_log_messages
      processing_events.map(&:message)
    end

    private

    def cache_event_message(message)
      cutoff = self.class.last_processing_message_limit
      self.last_processing_message = message[0...cutoff]
    end
  end

  class MissingRequiredColumns < TypeError ; end

  def self.included(receiver)
    require_processing_columns!(receiver)

    receiver.serialize :processing_log, Array

    # For ease of console debugging, we record the [first N chars of]
    # the last event message.  N depends on the individual table, so
    # pull the limit from the #columns
    receiver.class_attribute :last_processing_message_limit
    receiver.last_processing_message_limit = receiver.columns.detect {|e| e.name == "last_processing_message" } &.limit
    receiver.last_processing_message_limit ||= 100

    receiver.include InstanceMethods
  end

  def self.require_processing_columns!(model)
    missing_columns = REQUIRED_COLUMN_NAMES.reject { |col_name|
      model.column_names.include?(col_name)
    }

    if missing_columns.any?
      Rails.logger.error <<~EOF.strip
        #{model} attempted to include HasProcessingLog,
        but is missing the following required columns:
        #{missing_columns.inspect}
      EOF
    end
  end

end
