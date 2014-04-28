module Xe
  module Policy
    class Base
      # Callbacks for event state changes.

      # An event was added to the scheduler.
      def add_event(event); end
      # An event was removed from the scheduler. This could be due to a
      # sequence of scheduler runs (during finalization) or due to the forced
      # realization of some realizer group.
      def remove_event(event); end
      # A target was added to an existing event. Depending on the type of the
      # collection that backs the realizer's group, this may or may not
      # increase the cardinality of the event's group.
      def update_event(event); end
      # A fiber is blocked waiting on the realization of this event.
      def wait_event(event); end

      # Override to return an event key which should be realized immediately.
      # If nil is returned, the scheduler will make an arbitrary choice.
      def next_event_key
        nil
      end
    end
  end
end
