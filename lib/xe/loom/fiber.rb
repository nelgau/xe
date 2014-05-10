module Xe
  module Loom
    class Fiber < ::Fiber
      attr_reader :depth

      # Initialize the fiber to call the entry point.
      def initialize(loom, depth, &blk)
        @depth = depth
        super() do |*args|
          self.class.start(loom, *args, &blk)
        end
      end

      # The entry point for all fibers.
      def self.start(loom, *args, &blk)
        loom.fiber_started!
        blk.call(*args)
      ensure
        loom.fiber_finished!
      end
    end
  end
end
