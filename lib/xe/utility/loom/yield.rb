module Xe
  module Loom
    # This implementation assumes that all fibers within the context are
    # managed by this class and therefore that it's safe to use resume/yield to
    # pass control between enumerators and their blocks. Since this assumption
    # fails if the client application creates fibers of its own, the class is
    # designed to fail gracefully by forcing the immediate realization of any
    # values that are deferred within an unmanaged fiber.
    class Yield < Base
      # Yields from the current managed fiber and returns the result on resume.
      # If no managed fiber is available, it returns the value of the block.
      def wait(key, &blk)
        # If the current fiber isn't managed, we can't wait because we have
        # no assurances that it will behave as needed to correctly resolve all
        # dependencies without deadlocking
        current = Fiber.current
        return super unless managed_fiber?(current)
        # Add the fiber to the list of waiters on this key.
        push_waiter(key, current)
        # Yield back to whichever fiber that last called resume on the current,
        # one, returning control to either #run_fiber or #release.
        Fiber.yield
      end

      # Sequentially return control to all fibers that were suspended by
      # waiting on the given key. Control is transfered in the order the fibers
      # began waiting for consistency.
      def release(key, value)
        pop_waiters(key) do |waiter|
          waiter.resume(value)
        end
      end

      # Returns the depth of the current managed fiber, or zero if the current
      # is the root or unmanaged.
      def depth
        current = Fiber.current
        managed_fiber?(current) ? current.depth : 0
      end
    end
  end
end
