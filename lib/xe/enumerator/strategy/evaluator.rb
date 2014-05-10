module Xe
  class Enumerator
    module Strategy
      # Implements a strategy for evaluating a block within a single fiber. If
      # the computation blocks on the realization of a value, the strategy's
      # run method returns a proxy object.
      class Evaluator < Base
        attr_reader :target
        attr_reader :has_value
        attr_reader :value

        # Initializes a new instance for evaluating value_proc.
        def initialize(context, &value_proc)
          super(context)
          raise ArgumentError, "No block given" unless block_given?
          @value_proc = value_proc
          # Each instance of the evaluator strategy is unique. The result is
          # referenced by a distinct target constructed from the instance.
          @target = Target.new(self)
          @has_value = false
          @value = nil
        end

        # Evaluates value_proc within a single fiber and returns the value as
        # the result. If the computation blocks, a proxy object is returned.
        def call
          # Begin a new fiber and transfer control to (1).
          context.begin_fiber { evaluate }
          # (2) The fiber returned control. If we have a value, return it now.
          # Otherwise, the fiber is blocked in value_proc, so return a proxy.
          # In the proxy case, after realization, control will return to (3).
          @has_value ? @value : proxy
        end

        private

        # Evaluates value_proc immediately, stores/dispatches the result.
        def evaluate
          # (1) Evaluate value_proc with call. If the proc attempts to realize
          # a deferred value, the invocation will not return immediately and
          # instead transfer control to (2).
          @value = @value_proc.call
          # (3) Control returns, possibly after blocking.
          @has_value = true
          # After reaching here, it might be the case that we returned a proxy
          # for the result. Dispatch the computed value to the context to
          # resolve the proxy and release any fibers blocked on it.
          context.dispatch(@target, @value)
        end

        # Returns a proxy to the strategy's result. If an attempt is made to
        # resolve the subject outside of a managed fiber, the strategy will
        # call the context to finalize all outstanding events, releasing the
        # dependency on the strategy's fiber. After finalizing, the value must
        # be available, so return it as the subject.
        def proxy
          context.proxy(@target) do
            context.finalize!
            # The proxy accepts the returned value as its resolved subject.
            @value
          end
        end
      end
    end
  end
end
