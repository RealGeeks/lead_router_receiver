# This provides behavior related to the :processing_log,
# :processing_status, and :last_processing_message columns.
#
# This behavior was originally on LeadRouterMessage and has been
# extracted here to make it easier to reuse.
module LeadRouterReceiver
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

      if table_exists?(receiver) # see big comment in .require_processing_columns!
        col = receiver.columns.detect {|e| e.name == "last_processing_message" }
        receiver.last_processing_message_limit = col&.limit
      end
      receiver.last_processing_message_limit ||= 100

      receiver.include InstanceMethods
    end

    def self.require_processing_columns!(model)
      # When an app first includes this engine, this validation step
      # will crash until the migrations are run.  Unfortunately, Rails
      # seems to want to eager-load engines on startup, so the crash
      # prevents the app from loading, which means you're going to have
      # a bad time when you try to deploy.  If we can detect that the
      # table is missing, just quit and try again later.
      return unless table_exists?(model)

      # Still here?  Okay, *now* we can afford to be super picky.  :)
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



    def self.table_exists?(model)
      conn = ActiveRecord::Base.connection
      if conn.table_exists?( model.table_name )
        return true
      else
        Rails.logger.warn ">>> Including HasProcessingLog in #{model}, but the model's table is missing. Have you run migrations?"
        return false
      end
    end

  end
end
