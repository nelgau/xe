module Xe
  module Tracer
    class Event < Base
      attr_reader :events

      def initialize
        @events = []
      end

      def clear
        @events.clear
      end

      private

      def event_realize(event)
        @events << event
      end
    end
  end
end
