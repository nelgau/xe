module Xe
  module Logger
    class Event
      attr_reader :events

      def initialize
        @events = []
      end

      def event_realize(event)
        @events << event
      end
    end
  end
end
