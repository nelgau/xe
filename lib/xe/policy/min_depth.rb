module Xe
  module Policy
    class MinDepth < Base
      EventData = Struct.new(:event_key, :min_depth, :count, :index)

      attr_reader :events
      attr_reader :min_heap

      def initialize
        @events = {}
        @min_heap = []
      end

      # An event was added to the scheduler.
      def add_event(event)
        return if events[event.key]

        event_data = EventData.new(key, nil, event.count, nil)
        events[event.key] = event_data

      end

      # An event was removed from the scheduler.
      def remove_event(event)

      end

      # A fiber is blocked waiting on the realization of this event.
      def wait_event(event, depth)

      end

      # Returns an event key which should be realized immediately.
      # If nil is returned, the scheduler will make an arbitrary choice.
      def next_event_key
        nil
      end


      private

      def heapify(index)
    end
  end
end
