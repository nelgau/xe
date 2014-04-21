module Xe
  class Enumerator
    module Impl
      class Base
        attr_reader :context
        attr_reader :enum

        def initialize(context, enum)
          @context = context
          @enum = enum
        end

        protected

        def run(index=nil, &blk)
          # Run the block inside of a fiber.
          result = nil
          fiber = run_in_fiber do
            result = blk.call
            context.dispatch([self, index], result)
          end

          # The fiber terminated. Return the result as a value.
          return result if !fiber.alive?

          # The fiber is still alive. Wrap the result in a proxy.
          context.proxy(self, index) do
            # The proxy was realized in an unmanaged fiber so we can't wait for
            # the value to be available. We must finalize the context. This
            # necessarily releases all fibers (or deadlocks) so the result
            # must be available when this operation completes.
            context.finalize
            result
          end
        end

        def map_with_index(&blk)
          result = []
          enum.each_with_index do |obj, index|
            result << blk.call(obj, index)
          end
          result
        end

        private

        def run_in_fiber(&blk)
          context.fiber(&blk).tap(&:resume)
        end
      end
    end
  end
end
