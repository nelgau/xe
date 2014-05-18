module Xe
  class Enumerator
    # Implements the engine of fiber-based concurrency and proxying results.
    # Each fiber consumes and computes greedily until it encounters a deferred
    # realization then yields control. In its place, the strategy creates a new
    # fiber to pick up where the last left off. Proxies are substituted for
    # unrealized computation results.
    class Worker
      attr_reader :context
      attr_reader :enumerable
      attr_reader :tag

      # Invoked with each object consumed from the enumerable.
      attr_reader :compute_proc
      # Invoked with the result of the computation, or a proxy.
      attr_reader :results_proc

      def initialize(context, enumerable, options={})
        @context = context
        @enumerable = enumerable
        @tag = options[:tag]

        @compute_proc = options[:compute_proc] || lambda { |object| object }
        @results_proc = options[:results_proc] || lambda { |result| }

        @next_index = 0
        @done = false
      end

      # Evaluates compute_proc over the enumerable with many fibers. It invokes
      # results_proc for each result (either an immediate value or a proxy
      # if compute_proc blocks during execution).
      def call
        advance until done?
      end

      # Returns true when enumeration is complete.
      def done?
        @done
      end

      # Begin a new worker fiber. Each fiber is responsible for either:
      #
      #   1) Emitting a value by calling results_proc, or
      #   2) Terminating quietly after blocking on a deferred value.
      #
      # In the case of blocking on a deferred value (2), control will have
      # yielded back to #advance and the worker will have substituted a
      # proxy. Upon resuming, the fiber cannot complete any more iterations
      # because the worker isn't guaranteed be its parent fiber. The fiber
      # detects this condition with the `did_proxy` attribute and terminates.
      def advance
        # Initialize local state. These instance variables will be shared
        # only with the fiber created in this scope and it alone.
        object = index = target = value = nil
        has_value = did_proxy = false

        # Greedily consume objects from the enumerable until we run out, or
        # we know that evaluating the iterator blocked and substituted a
        # proxy. Start execution in the fiber at (1).
        @context.begin_fiber do
          # (1) Iterate until we run out of objects. Each iteration will add
          # a new object to the results by either #emit_value or #emit_proxy.
          loop do
            # Reset the state for the next iteration.
            has_value = false
            did_proxy = false

            begin
              # Consume a new object from the enumerable. If there are no
              # objects left, it raises StopIteration and proceeds to (2).
              object = consumer.next
              index = @next_index
              @next_index += 1
            rescue StopIteration
              # (2) The enumeration is complete. Return from the fiber.
              @done = true
              break
            end

            # Evaluate compute_proc with call. If the proc attempts to
            # realize a deferred value, the invocation will not return
            # immediately and instead transfer control to (3).
            value = @compute_proc.call(object, index)

            # (4) The value is computed. After reaching here, it might be the
            # case that we substituted a proxy for the result.
            has_value = true

            if did_proxy
              # We returned a proxy to the result. Dispatch the computed
              # value to the context. This resolves the proxy and releases
              # any fibers blocked on it. Target will be assigned below.
              @context.dispatch(target, value)
              # This fiber has completed its responsibilities and another
              # fiber has continued the enumeration. Terminate immediately.
              break
            else
              # Since we didn't proxy the result, the fiber is responsible for
              # emitting the new value to results_proc.
              @results_proc.call(value, object)
            end
          end
        end

        # (3) The fiber returned control. If enumeration is complete, stop.
        return if done?

        # If the last iteration has no value, it's now our responsibility to
        # emit a proxy for the result. In that case, after realization,
        # control will return to (4).
        if !has_value
          # Each proxied result value of the worker is unique and is referenced
          # by a target constructed from the instance and the index.
          target = Target.new(self, index)
          # Creates a proxy to the result of the given iterator. If an
          # attempt is made to resolve the subject outside of a managed
          # fiber, the worker will call the context to finalize all
          # outstanding events, releasing the dependency on the worker's
          # fiber. After finalizing, the value must be available, so return
          # it as the subject.
          proxy = @context.proxy(target) do
            @context.finalize!
            # The proxy accepts the returned value as its resolved subject.
            value
          end
          # Record that we substituted a proxy.
          did_proxy = true
          # Emit the the proxy to results_proc.
          @results_proc.call(proxy, object)
        end
      end

      def inspect
        "#<#{self.class.name} (#{@tag || '...'})>"
      end

      def to_s
        inspect
      end

      private

      # Returns a memoized enumerator for consuming elements. Don't create
      # this during initialization in case the enumerable itself is a proxy.
      def consumer
        @consumer ||= ::Enumerator.new(@enumerable)
      end
    end
  end
end
