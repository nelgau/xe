module Xe
  module Loom
    # The superclass of all loom exceptions.
    class Error < StandardError; end

    # This class is responsible for creating managed fibers, suspending their
    # execution into keyed groups, and returning control to these groups of
    # suspended fibers with a given value.
    class Base
      attr_reader :waiters

      def initialize
        @waiters = {}
      end

      # Creates a new managed fiber.
      def new_fiber(&blk)
        Xe::Fiber.new(self, current_depth + 1, &blk)
      end

      # Transfer control to a managed fiber for the first time.
      def run_fiber(fiber, *args)
        fiber.resume(*args)
      end

      # Returns true if the fiber is managed.
      def managed_fiber?(fiber)
        fiber.is_a?(Xe::Fiber)
      end

      # Suspend the current fiber until the given key is released with a value.
      # If the current fiber can't be suspended, the block is invoked if given,
      # and the result is returned. The default implementation can't suspend.
      def wait(key, &blk)
        blk.call(key) if block_given?
      end

      # Sequentially return control to all fibers that were suspended by
      # waiting on the given key. Control is transfered in the order the fibers
      # began waiting for consistency. The default implementation is empty
      # because the base class doesn't suspend fibers.
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

      # Returns the depth of the current fiber as an integer. The default
      # implementation considers all fibers to be unnested and therefore
      # at a depth of one (relative to the root).
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
    end
  end
end
