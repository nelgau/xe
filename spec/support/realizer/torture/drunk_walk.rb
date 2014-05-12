module Xe::Test
  module Realizer
    # This is a rather insane torture test, explicitly designed to be recursive,
    # reentrant and somewhat unpredictable, with realizations that will unblock
    # fibers at many differrent depths at once. The design of Xe::Enumerator
    # and Xe::Realizer::Base permits us to execute this beast in many different
    # ways -- from serialized (disabled context) to thousands of fibers.
    class DrunkWalk < Xe::Realizer::Base
      # Just choose a few naughty numbers that are unlikely to combine to
      # form simple patterns.
      WIDTH  = 23
      PRIME1 = 13
      PRIME2 = 7

      # To start the adventure, just realize this value in a context.
      def self.start(depth=4)
        for_depth(depth)[1]
      end

      def self.for_depth(depth)
        all_depths[depth] ||= new(depth)
      end

      private

      def self.all_depths
        @all_depths ||= {}
      end

      attr_reader :depth

      def initialize(depth)
        @depth = depth
      end

      def perform(group)
        return group if depth == 0
        realizer = DrunkWalk.for_depth(depth - 1)
        enum = group.map { |id| (0...WIDTH).map { |i| PRIME2 * id + i } }
        Xe.map(enum) { |nested| Xe.map(nested) { |id| realizer[id] } }
      end

      def group_key(id)
        id % PRIME1
      end
    end
  end
end
