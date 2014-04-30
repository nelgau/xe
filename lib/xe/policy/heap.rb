require 'set'

module Xe
  module Policy
    class Heap < Base
      # Event metadata for proritization.
      class EventData
        # Arbitrarily chosen to be a positive integer larger than any
        # conceivable fiber depth. Ruby has no definitions for numerical bounds.
        MAX_DEPTH = 2 ** 24

        attr_reader :event
        attr_reader :min_depth

        def initialize(event, min_depth=nil)
          @event = event
          @min_depth = min_depth || MAX_DEPTH
        end

        def apply_depth(depth)
          @min_depth = depth if depth < @min_depth
        end

        def count
          event.count
        end
      end

      # Unless otherwise specified with the constructor, this class will use
      # the following comparator to order events for realizaion.
      def self.default_priority
        @default_priority ||= Proc.new do |ed1, ed2|
          # Lowest depth is maximally interesting as it potentially unblocks
          # larger wins that are nested deeply and diffusely.
          cmp = ed2.min_depth <=> ed1.min_depth
          next cmp if cmp != 0
          # Otherwise, choose the smallest count. The rationale is that big
          # groups are likely to become even bigger as the search proceeds,
          # possibly allowing for very large batching gains at the end.
          ed2.count <=> ed1.count
        end
      end

      attr_reader :priority
      attr_reader :queue
      attr_reader :updated_keys

      def initialize(&priority)
        @priority = priority || self.class.default_priority
        @queue = Xe::Heap.new(&@priority)
        @updated_keys = Set.new
      end

      # An event was added to the scheduler.
      def add_event(event)
        @queue[event.key] = EventData.new(event)
      end

      # An event was removed from the scheduler.
      def remove_event(event)
        key = event.key
        @queue.delete(key)
        @updated_keys.delete(key)
      end

      # A target was added to an existing event.
      def update_event(event)
        key = event.key
        return unless @queue.has_key?(key)
        @updated_keys << key
      end

      # A fiber is blocked waiting on the realization of this event.
      def wait_event(event, depth)
        key = event.key
        data = @queue[key]
        return unless data
        data.apply_depth(depth)
        @updated_keys << key
      end

      # Return an event key which should be realized immediately.
      def next_event_key
        flush_updates
        key, _ = queue.pop
        key
      end

      private

      def flush_updates
        @updated_keys.each { |k| queue.update(k) }
        @updated_keys.clear
      end
    end
  end
end
