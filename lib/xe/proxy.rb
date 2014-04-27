module Xe
  class Proxy < BasicObject
    attr_reader :__target

    def initialize(&target_block)
      @__target_block = target_block
      @__has_target = false
    end

    def __target?
      @__has_target
    end

    def __set_target(target)
      @__target = target
      @__has_target = true
      # Allow the garbage collector to reclaim the block's scope.
      @__target_block = nil
    end

    def __resolve_target
      __set_target(@__target_block.call)
    end

    def method_missing(method, *args, &blk)
      __resolve_target unless __target?
      @__target.__send__(method, *args, &blk)
    end
  end
end
