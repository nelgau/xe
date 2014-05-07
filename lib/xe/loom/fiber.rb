module Xe
  module Loom
    module Fiber
      # Returns the current fiber.
      def self.current
        ::Fiber.current
      end

      # Creates a new managed fiber.
      def self.new(*args, &blk)
        ::Fiber.new do |*args, &fblk|
          begin
            started!
            blk.call(*args, &fblk)
          rescue => e
            puts "Uncaught exception in fiber! #{e}"
            raise e
          ensure
            finished!
          end
        end
      end

      # Transfer control back to the given fiber.
      def self.resume(fiber)
        fiber.resume(fiber)
      end

      # Yields execution from the current fiber.
      def self.yield
        ::Fiber.yield
      end

      # Called when a fiber begins executing.
      def self.started!
        # context.fiber_started(current) if context
      end

      # Called when a fiber finishes executing
      def self.finished!
        # context.fiber_finished(current) if context
      end

      # Returns the current thread-local context, or nil if none exists.
      def self.context
        Context.current
      end
    end
  end
end
