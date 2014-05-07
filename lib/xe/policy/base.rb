module Xe
  module Policy
    class Base
      # Callbacks for state changes.

      # An event was added to the scheduler.
      def add_event(event); end
      # An event was removed from the scheduler. This could be due to a
      # sequence of scheduler runs (e.g., during finalization or hitting the
      # fiber ceiling) or due to the forced realization of a deferred target.
      def remove_event(event); end
      # A target was added to an existing event. Depending on the behavior of
      # the collection that backs the realizer's group, this may or may not
      # increase the cardinality of the event's group.
      def update_event(event); end
      # A fiber is blocked on the realization of this event. The depth of the
      # fiber is given as the second argument.
      def wait_event(event, depth); end

      # Returns the key for whichever event should be realized immediately. If
      # nil is returned, the scheduler will make an arbitrary choice.
      def next_event_key
        nil
      end

      def inspect
        "#<#{self.class.name}>"
      end

      def to_s
        inspect
      end
    end
  end
end
