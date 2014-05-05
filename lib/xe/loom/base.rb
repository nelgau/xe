module Xe
  module Loom
    # The superclass of all loom exceptions.
    class Error < StandardError; end

    # This class is responsible for creating managed fibers, suspending their
    # execution into keyed groups, and returning control to these groups by
    # resuming with a given value.
    class Base
      attr_reader :waiters
      attr_reader :running_fibers

      def initialize
        @waiters = {}
        @running_fibers = Set.new
      end

      # Creates a new managed fiber.
      def new_fiber(&blk)
        Loom::Fiber.new(self, current_depth + 1) do |*args, &fblk|
          begin
            fiber_started
            blk.call(*args, &fblk)
          ensure
            fiber_ended
          end
        end
      end

      # Transfer control to a managed fiber for the first time.
      def run_fiber(fiber, *args)
        fiber.resume(*args)
      end

      # Returns true if the fiber is managed.
      def managed_fiber?(fiber)
        fiber.is_a?(Loom::Fiber)
      end

      # Suspend the current fiber until the given key is released with a value.
      # When the value become available, it is returned from the invocation.
      # If the current fiber can't be suspended, the block is invoked if given,
      # and the result is returned. The default implementation can't suspend.
      def wait(key, &blk)
        blk.call(key) if block_given?
      end

      # Sequentially return control to all fibers that are waiting on the given
      # key. Control is transfered in the order the fibers began waiting for
      # consistency. The default implementation is empty as the base class
      # can't suspend fibers.
      def release(key, value)
        return
      end

      # Returns true if any fibers are presently suspended.
      def waiters?
        waiters.any?
      end

      # Returns the count of fibers suspended on the given key.
      def waiter_count(key)
        fibers = waiters[key]
        fibers ? fibers.count : 0
      end

      # Returns the depth of the current fiber. The default implementation
      # considers all fibers to be unnested and therefore at a depth of zero.
      def current_depth
        0
      end

      # @protected
      # Pushes a waiter onto the list of a given key. Waiters can be arbitrary
      # values (i.e., fibers or other data structures).
      def push_waiter(key, waiter)
        (waiters[key] ||= []) << waiter
      end

      # @protected
      # Pop and enumerate all waiters for a given key. These waiters are
      # dequeued immediately and all at once to clear the path for new waiters
      # that might block on the same key after control is resumed.
      def pop_waiters(key, &blk)
        key_waiters = waiters.delete(key)
        return unless key_waiters
        key_waiters.each(&blk)
      end

      # @protected
      # Adds the current fiber to the running set.
      def fiber_started
        @running_fibers << Fiber.current
      end

      # @protected
      # Removes the current fiber from the running set.
      def fiber_ended
        @running_fibers.delete(Fiber.current)
      end
    end
  end
end
