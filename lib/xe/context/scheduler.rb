module Xe
  class Context
    class Scheduler
      attr_reader :policy
      attr_reader :events

      def initialize(policy)
        @policy = policy
        @events = {}
      end

      def add(target)
        event = create_event(target)
        event << target.id
        policy.update_event(event)
      end

      def wait(target, depth)
        key = Event.target_key(target)
        event = events[key]
        policy.wait_event(event, depth) if event
      end

      # Pops and returns an event, or nil.
      def next_event
        # Give the policy the oportunity to select the event. If the policy
        # defers the decision (by returning nil), select the first event in the
        # hash. Thanks to Ruby's ordered hashes this will also have the
        # property of consuming the events in the order they were added.
        key   = policy.next_event_key
        key ||= events.each_key.first
        consume_event(key)
      end

      # Pops and returns the event associated with this target, or returns nil
      # if no such event exists.
      def pop_event(target)
        key = Event.target_key(target)
        consume_event(key)
      end

      def empty?
        events.empty?
      end

      private

      def create_event(target)
        key = Event.target_key(target)
        events[key] ||= begin
          Event.for_target(target).tap do|event|
            policy.add_event(event)
          end
        end
      end

      def consume_event(key)
        events.delete(key).tap do |event|
          policy.remove_event(event) if event
        end
      end
    end
  end
end
