require 'fiber'

module Xe
  module Loom
    class Fiber < ::Fiber
      attr_reader :loom
      attr_reader :depth

      def initialize(loom, depth, &blk)
        @loom = loom
        @depth = depth
        super(&blk)
      end

      # Transfers control into the fiber for the first time.
      def run(*args)
        loom.run_fiber(self, *args)
      end
    end
  end
end
