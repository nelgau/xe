module Xe
  class Context
    class Queue
      include Enumerable

      attr_reader :queued

      def initialize(&did_realize)
        @did_realize = did_realize
        # Map of [realizer, group key] => group.
        @queued = {}
      end

      def each(&blk)
        queued.each(&blk)
      end

      def empty?
        queued.empty?
      end

      def add(realizer, id)
        group_key = realizer.group_key_for_id(id)
        key = [realizer, group_key]
        group = (queued[key] ||= realizer.new_group(group_key))
        group << id
        [group_key, group]
      end

      def realize(realizer, id)
        group_key, group = add(realizer, id)
        realize_group(realizer, group_key, group)
      end

      def flush
        last_queued = queued.dup
        queued.clear

        last_queued.each do |(realizer, group_key), group|
          realize_group(realizer, group_key, group)
        end
      end

      def group_count
        @queued.count
      end

      def item_count
        @queued.values.map(&:count).reduce(0, &:+)
      end

      private

      def realize_group(realizer, group_key, group)
        results = realizer.call(group_key, group)
        group.each do |id|
          @did_realize.call(realizer, id, results[id])
        end
      end
    end
  end
end
