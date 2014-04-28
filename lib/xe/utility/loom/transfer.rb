module Xe
  module Loom
    # This implementation takes into account the possibility that the body of
    # an enumeration or realizer may itself use fibers to implement another
    # layer of cooperative concurrency. It explicitly transfers control between
    # fibers instead of using resume/yield.
    #
    # *** NOTE: While this is correct for the most part, on Ruby 1.9.3-p448,
    # the implementation segfaults when an exception is thrown from a fiber
    # into which control has been transferred.
    class Transfer < Base
      # Thrown when the current stack and control flow cannot be reconciled.
      # This should never occur under normal circumstances and indicates that
      # there'ss a serious bug in the implementation of this class.
      class InconsistentStackError < Error; end

      Frame  = Struct.new(:running_fiber, :calling_fiber)
      Waiter = Struct.new(:waiting_fiber, :managed_fiber)

      attr_reader :stack

      def initialize
        super
        # Initially place the root fiber at the top of the stack. It has no
        # calling fiber and we raise if an attempt is made to unwind from it.
        root_frame = Frame.new(Fiber.current, nil)
        @stack = [root_frame]
      end

      # Returns the depth of the current fiber as an integer.
      def depth
        # The root fiber has a depth of zero.
        top_fiber = stack.last
        managed_fiber?(top_fiber) ? top_fiber.depth : 0
      end

      # Creates a new managed fiber. As control may transfer from it without
      # using Fiber.yield, the parent (the ) may have finished executing when
      # control returns (by releasing). This case is handled by unwinding the
      # stack on termination and transferring control back to #release.
      def new_fiber(&blk)
        super do |parent, *args|
          blk.call(*args)
          # If the fiber that called #run_fiber is not alive, jump up the stack
          # to whichever last transferred control to this one.
          unwind_stack unless parent.alive?
        end
      end

      # Transfer control to a managed fiber for the first time. The fiber is
      # pushed onto the stack and a reference to the current fiber (parent) is
      # passed to the entry point.
      def run_fiber(fiber, *args)
        push_stack(fiber) do |parent|
          super(fiber, parent, *args)
        end
      end

      # Yields from the current fiber and returns the result on resume.
      # If no managed fiber is available, it returns the value of the block.
      def wait(key, &blk)
        # We're at the root. We can't wait.
        return super if stack.count < 2
        # How can these be different? The client of an enumeration operation
        # may be using unmanaged fibers to support some other form of
        # concurrency so we can't asssume that the managed fiber at the top of
        # the stack is identical to the one that's blocking. However, when
        # this is not the case, waiting_fiber and managed_fiber are identical.
        waiting_fiber = Fiber.current
        managed_fiber = stack.last.running_fiber
        # Add the fiber to the list of waiters on this key.
        waiter = Waiter.new(waiting_fiber, managed_fiber)
        push_waiter(key, waiter)
        # Transfer control back to the enclosing enumeration. When control
        # returns in that fiber, the waiter will be at the top of the stack
        # and ready to be popped off.
        stack[-2].running_fiber.transfer
      end

      # Sequentially return control to all fibers that were suspended by
      # waiting on the given key. Control is transfered in the order the fibers
      # began waiting for consistency. The managed fiber associated with each
      # waiter is pushed onto the stack before control is transferred back
      # to the suspended fiber.
      def release(key, value)
        pop_waiters(key) do |waiter|
          push_stack(waiter.managed_fiber) do
            waiter.waiting_fiber.transfer(value)
          end
        end
      end

      private

      # Pushes a single frame onto the stack and yields control to the given
      # block. When control returns, the stack frame is popped and the running
      # fiber is compared to the one that was initially pushed. If this
      # implementation's control transfer strategy is consistent, these must be
      # equal so an exception is raised otherwise.
      def push_stack(fiber)
        current_fiber = Fiber.current
        stack << Frame.new(fiber, current_fiber)
        result = yield current_fiber
        returning_fiber = stack.pop.running_fiber
        raise InconsistentStackError if fiber != returning_fiber
        result
      end

      # Returns control to whichever fiber transferred control to the fiber at
      # the top of the stack. This method should only ever transfer back to
      # the #release operation.
      def unwind_stack
        calling_fiber = stack.last.calling_fiber
        raise InconsistentStackError unless calling_fiber
        calling_fiber.transfer
      end
    end
  end
end
