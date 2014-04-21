module Xe
  class Context

    class Scheduler
      attr_reader :waiting

      def initialize
        @waiting = Hash.new {[]}
      end

      def fiber(&blk)
        Context::Fiber.new(self, &blk)
      end

      # Yields from the current managed fiber and returns the result on resume.
      # If no managed fiber is available, it returns the value of the block.
      def wait(key, &blk)
        fiber = ::Fiber.current
        if managed?(fiber)
          waiting[key] << fiber
          ::Fiber.yield
        else
          blk.call
        end
      end

      def dispatch(key, value)
        fibers = waiting.delete(key)
        return unless fibers
        fibers.each { |f| f.resume(value) }
      end

      def waiters?
        waiting.any?
      end

      def managed?(fiber)
        fiber.is_a?(Context::Fiber)
      end
    end

  end
end
