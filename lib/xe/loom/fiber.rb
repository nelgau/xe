module Xe
  module Loom
    class Fiber < ::Fiber
      attr_reader :depth

      def initialize(loom, depth, &blk)
        @depth = depth
        super() { Fiber.start(loom, &blk) }
      end

      def self.start(loom, &blk)
        loom.fiber_started!
        blk.call
      ensure
        loom.fiber_finished!
      end
    end
  end
end
