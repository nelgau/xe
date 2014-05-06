module Xe
  class Enumerator
    module Impl
      class Map < Base
        def map(&blk)
          map_with_index do |obj, index|
            run(index) { blk.call(obj) }
          end
        end







        # def map(&blk)

        #   producer = Enumerator.new(enum)
        #   results = []

        #   begin
        #     loop do

        #       fiber_target = nil
        #       fiber_result = nil
        #       did_suspend = false

        #       fiber = run_in_fiber do

        #         loop do
        #           obj = producer.next
        #           index = results.length

        #           # Create a new target for this component of the enumeration.
        #           fiber_target = Target.new(self, index)

        #           fiber_result = blk.call(obj)
        #           context.dispatch(target, fiber_result)

        #           # If the fiber suspended, we should not continue enumeration
        #           # are set the result, as some other process will take care of
        #           # this for us.
        #           break if did_suspend

        #           result[index] = fiber_result
        #         end

        #       end

        #       # If the first is still alive, we need to make that it doesn't
        #       # continue to consume from the producer
        #       if fiber.alive?
        #         # Signal to the fiber that it should terminate once control
        #         # returns from the loom.
        #         did_suspend = true

        #         # Wrap the result in a proxy.
        #         result[index] = context.proxy(fiber_target) do
        #           # The proxy was realized in an unmanaged fiber so we can't wait for
        #           # the value to be available. We must finalize the context. This
        #           # necessarily releases all fibers (or deadlocks) so, assuming the
        #           # operation succeeds the result must be available.
        #           context.finalize
        #           fiber_result
        #         end

        #       end

        #     end
        #   # Thrown by producer#next when the enumerable is exhausted.
        #   rescue StopIteration
        #   end







      end
    end
  end
end
