module Xe
  class Context
    class Event
      include Enumerable
      include Comparable

      attr_reader :key
      attr_reader :realizer
      attr_reader :group_key
      attr_reader :group

      def self.for_target(target)
        realizer = target.source
        group_key = realizer.group_key_for_id(target)
        group = realizer.new_group(group_key)
        new(realizer, group_key, group)
      end

      def self.key(realizer, group_key)
        [realizer, group_key]
      end

      def self.target_key(target)
        key(target.source, target.group_key)
      end

      def initialize(realizer, group_key, group)
        @key = Event.key(realizer, group_key)
        @realizer = realizer
        @group_key = group_key
        @group = group
      end

      def <<(id)
        group << id
      end

      def realize(&blk)
        results = realizer.call(group_key, group)
        each { |t| yield t, results[t.id] }
        results
      end

      def each(&blk)
        group.each { |id| blk.call(target_for_id(id)) }
      end

      def count
        group.count
      end

      def inspect
        "<#Xe::Event key: [#{realizer}" \
        "#{group_key ? ", #{group_key}" : nil}] " \
        "count: #{count}>"
      end

      def to_s
        inspect
      end

      private

      def target_for_id(id)
        Target.new(realizer, id, group_key)
      end
    end
  end
end
