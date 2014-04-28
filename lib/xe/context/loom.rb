module Xe
  class Context
    class Loom
      attr_reader :waiters

      def initialize
        @waiters = {}
      end

      # Creates a new managed fiber.
      def fiber(&blk)
        Xe::Fiber.new(&blk)
      end

      # Returns true if the fiber is managed.
      def managed_fiber?(fiber)
        fiber.is_a?(Xe::Fiber)
      end

      # Yields from the current managed fiber and returns the result on resume.
      # If no managed fiber is available, it returns the value of the block.
      def wait(key, &blk)
        fiber = ::Fiber.current
        if managed_fiber?(fiber)
          (waiters[key] ||= []) << fiber
          ::Fiber.yield
        else
          blk.call(key)
        end
      end

      def release(key, value)
        fibers = waiters.delete(key)
        return unless fibers
        fibers.each { |f| f.resume(value) }
      end

      def waiters?
        waiters.any?
      end

      def waiter_count(key)
        fibers = waiters[key]
        fibers ? fibers.count : 0
      end
    end
  end
end
