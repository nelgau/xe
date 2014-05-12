module Xe
  class Enumerator
    module Strategy
      # Implements a strategy for evaluating a block within a single fiber. If
      # the computation blocks on the realization of a value, the strategy's
      # run method returns a proxy object.
      class Evaluator < Base
        def initialize(context, &value_proc)
          super(context)
          raise ArgumentError, "No block given" unless block_given?
          @value_proc = value_proc
        end

        # Evaluates value_proc within a single fiber and returns the value as
        # the result. If the computation blocks, a proxy object is returned.
        def call
          # Each instance of the evaluator strategy is unique. The result is
          # referenced by a distinct target constructed from the instance.
          target = Target.new(self)
          value = nil
          has_value = did_proxy = false

          # Begin a new fiber and transfer control to (1).
          context.begin_fiber do
            # (1) Evaluate value_proc with call. If the proc attempts to realize
            # a deferred value, the invocation will not return immediately and
            # instead transfer control to (2).
            value = @value_proc.call

            # (3) The value is computed. After reaching here, it might be the
            # case that we substituted a proxy for the result.
            has_value = true

            if did_proxy
              # We returned a proxy to the result. Dispatch the computed
              # value to the context. This resolves the proxy and releases
              # any fibers blocked on it.
              context.dispatch(target, value)
            end
          end

          # (2) The fiber returned control. If we don't have a value, the fiber
          # is blocked in value_proc so we must return a proxy. In that case,
          # after realization, control will return to (3).
          if !has_value
            # Record that we substituted a proxy.
            did_proxy = true

            # Returns a proxy to the strategy's result. If an attempt is made
            # to resolve the subject outside of a fiber, the strategy will call
            # to finalize the context and all outstanding events, releasing the
            # dependency on the strategy's fiber. After finalizing, the value
            # must be available, so return it as the subject.
            context.proxy(target) do
              context.finalize!
              # The proxy accepts the returned value as its resolved subject.
              value
            end
          else
            # We have a value, simply return it.
            value
          end
        end
      end
    end
  end
end
