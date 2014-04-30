module Xe
  class Event
    include Enumerable
    include Comparable

    attr_reader :key
    attr_reader :deferrable
    attr_reader :group_key
    attr_reader :group

    def self.from_target(target)
      deferrable = target.source
      # The target's source must be an instance of deferrable.
      raise DeferError if !deferrable.is_a?(Deferrable)

      group_key = deferrable.group_key_for_id(target)
      group = deferrable.new_group(group_key)
      new(deferrable, group_key, group)
    end

    def self.key(deferrable, group_key)
      [deferrable, group_key]
    end

    def self.target_key(target)
      key(target.source, target.group_key)
    end

    def initialize(deferrable, group_key, group)
      @key = Event.key(deferrable, group_key)
      @deferrable = deferrable
      @group_key = group_key
      @group = group
    end

    def <<(id)
      group << id
    end

    def realize(&blk)
      results = deferrable.call(group)
      each { |t| yield t, results[t.id] }
      results
    end

    def each(&blk)
      to_enum.each(&blk)
    end

    def count
      group.count
    end

    def inspect
      "<#Xe::Event key: [#{deferrable}" \
      "#{group_key ? ", #{group_key}" : nil}] " \
      "count: #{count}>"
    end

    def to_s
      inspect
    end

    private

    def to_enum
      ::Enumerator.new do |y|
        group.each do |id|
          y << Target.new(@deferrable, id, @group_key)
        end
      end
    end
  end
end
