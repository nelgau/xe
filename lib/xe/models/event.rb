module Xe
  class Event
    include Enumerable

    attr_reader :deferrable
    attr_reader :group_key
    attr_reader :group
    attr_reader :key

    # Create an event that represents a group of targets.
    def self.from_target(target)
      deferrable = target.source
      # The target's source must be an instance of deferrable.
      if !deferrable.is_a?(Deferrable)
        raise DeferError, "The target's source isn't deferrable."
      end
      new(deferrable, target.group_key)
    end

    # Returns the event key for the given deferrable group.
    def self.key(deferrable, group_key)
      [deferrable, group_key]
    end

    # Retruns the event key for the given target.
    def self.target_key(target)
      key(target.source, target.group_key)
    end

    def initialize(deferrable, group_key)
      @deferrable = deferrable
      @group_key = group_key
      @group = deferrable.new_group(group_key)
      @key = Event.key(deferrable, group_key)
    end

    # Adds a single id to the event's group.
    def <<(id)
      group << id
    end

    # Realizes all values in the event's group using the deferrable and returns
    # the result as a hash from ids to values. If a block is given, it invokes
    # the block once for each id, with the id's target and value.
    def realize
      results = deferrable.call(group, group_key)
      targets.each { |t| yield(t, results[t.id]) } if block_given?
      results
    end

    # Enumerates over all targets in the event.
    def each
      group.each
    end

    # Returns the count of ids in the event's group.
    def length
      group.length
    end

    # Returns true if the event is empty.
    def empty?
      group.empty?
    end

    def targets
      group.map do |id|
        Target.new(@deferrable, id, @group_key)
      end
    end

    def inspect
      "<#Xe::Event key: [#{deferrable}" \
      "#{group_key ? ", #{group_key}" : nil}] " \
      "length: #{length}>"
    end

    def to_s
      inspect
    end
  end
end
