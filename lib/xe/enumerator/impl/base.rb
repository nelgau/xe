module Xe
  class Enumerator
    module Impl
      class Base
        attr_reader :context
        attr_reader :enum
        attr_reader :tag

        def initialize(context, enum, options)
          @context = context
          @enum = enum
          @tag = options[:tag]
        end

        def inspect
          # Shorten the length of the class name to improve readability.
          last_const_name = self.class.name.split('::').last
          "#<Enum/#{last_const_name}#{tag && "(#{tag})"}>"
        end

        def to_s
          inspect
        end

        protected

        def run(index=nil, &blk)
          # If the context is disabled, return the evaluated block without
          # deferring, proxying or any fiber-based enumeration.
          return blk.call if context.disabled?

          # Create a new target for this component of the enumeration.
          target = Target.new(self, index)

          # Run the block inside of a fiber.
          result = nil
          fiber = run_in_fiber do
            result = blk.call
            context.dispatch(target, result)
          end
          # The fiber terminated. Return the result as a value.
          return result if !fiber.alive?

          # The fiber is still alive. Wrap the result in a proxy.
          context.proxy(target) do
            # The proxy was realized in an unmanaged fiber so we can't wait for
            # the value to be available. We must finalize the context. This
            # necessarily releases all fibers (or deadlocks) so, assuming the
            # operation succeeds the result must be available.
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
          context.fiber(&blk).tap(&:run)
        end
      end
    end
  end
end
