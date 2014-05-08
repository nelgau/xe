require 'fiber'

module Xe
  class Fiber < ::Fiber
    attr_reader :loom
    attr_reader :depth

    def initialize(loom, depth, &blk)
      @loom = loom
      @depth = depth
      super(&blk)
    end

    def run(*args)
      loom.run_fiber(self, *args)
    end
  end
end
