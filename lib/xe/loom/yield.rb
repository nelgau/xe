module Xe
  module Loom
    # This implementation assumes that all fibers within the context are
    # managed by this class and that it's safe to use resume/yield to pass
    # control between enumerators and their blocks. Since this assumption fails
    # when the client application creates fibers of its own, this class was
    # designed to fail gracefully by forcing the immediate realization of any
    # values that are deferred in an unmanaged fiber.
    class Yield < Base
      # Yields from the current managed fiber and returns the result on resume.
      # If no managed fiber is available, it returns the value of the block.
      def wait(key, &cantwait_proc)
        current = ::Fiber.current
        # If the current fiber isn't managed, we can't wait because we have
        # no assurances that it will behave as needed to correctly resolve all
        # dependencies without deadlocking. Calling `super` here will force
        # realization via the block.
        return super unless managed_fiber?(current)
        # Add the fiber to the list of waiters on this key.
        push_waiter(key, current)
        # Yield back to whichever fiber that last called Fiber#resume,
        # returning control to either Loom#run_fiber or Loom#release.
        ::Fiber.yield
      end

      # Sequentially returns control to all fibers that were suspended by
      # waiting on the given key. Control is transfered back in the order that
      # the fibers began waiting for consistency.
      def release(key, value)
        waiters = pop_waiters(key)
        return unless waiters
        while w = waiters.pop
          w.resume(value)
        end
      end

      # Releases all waiting fibers with a nil value, ignoring return values
      # and exceptions.
      def clear
        while (key = waiters.each_key.first)
          waiters = pop_waiters(key)
          next unless waiters
          while w = waiters.pop
            w.resume(nil) rescue nil
          end
        end
      end

      # Returns the depth of the current managed fiber, or zero if the current
      # is the root or unmanaged.
      def current_depth
        current = Fiber.current
        managed_fiber?(current) ? current.depth : 0
      end
    end
  end
end
