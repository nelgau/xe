module Xe
  class Context
    class Scheduler
      attr_reader :policy
      attr_reader :events

      def initialize(policy)
        @policy = policy
        @events = {}
      end

      # Adds a target to the queue of realizations, creating an event for it
      # if one doesn't already exist. It notifies the policy of the change.
      def add_target(target)
        key = Event.target_key(target)
        event = events[key]
        if event
          # If event exists, extend it with the id of the target.
          event << target.id
          policy.update_event(event)
        else
          # The event doesn't exists so create a new one.
          event = Event.from_target(target)
          events[key] = event
          event << target.id
          policy.add_event(event)
        end
      end

      # Notifies the policy that a fiber is waiting on the realization of the
      # given target (at a particular depth).
      def wait_target(target, depth)
        key = Event.target_key(target)
        event = events[key]
        policy.wait_event(event, depth) if event
      end

      # Removes and returns an event from the queue of realizations, in the
      # order specified by the policy, or nil if the queue is empty.
      def next_event
        # Allow the policy the first oportunity to select the event. If the
        # policy defers the decision (by returning nil), select the first event
        # in the hash. Thanks to Ruby's ordered hashes, this has the property
        # of consuming the events in the order that they were added.
        key   = policy.next_event_key
        key ||= events.each_key.first
        consume_event(key)
      end

      # Removes and returns the event associated with this target, or nil if
      # no such event exists.
      def pop_event(target)
        key = Event.target_key(target)
        consume_event(key)
      end

      # Returns true if there are no events waiting to be realized.
      def empty?
        events.empty?
      end

      private

      # Removes and returns the event with the given key. It also notifies the
      # policy that the event was removed.
      def consume_event(key)
        events.delete(key).tap do |event|
          policy.remove_event(event) if event
        end
      end
    end
  end
end
