module LeadRouterReceiver
  class Clock
    SUBSECOND_PRECISION_DIGITS = 6 # microseconds are Quite Good Enough, Thank You(tm)

    # Convenience constructor for use in specs.
    # Example use: Clock.as_of( 1.hour.from_now )
    def self.as_of(time)
      new(time)
    end

    # Apparently stubbing .new doesn't work so well, so we'll go with
    # Clock.for_current_time instead.
    def self.for_current_time
      new( Time.now )
    end

    # Another quick convenience method
    def self.current_time
      for_current_time.to_time
    end

    def initialize(time)
      @time = time.utc
    end

    def to_time
      time.round(SUBSECOND_PRECISION_DIGITS)
    end

    def plus( duration )
      Clock.as_of( time + duration )
    end

    def minus( duration )
      Clock.as_of( time - duration )
    end

    # This is here to facilitate tests of sleep-based behavior.
    def sleep(duration)
      super # invoke Kernel#sleep
    end

    private
    attr_reader :time
  end
end
