module Xe
  class Enumerator
    module Strategy
      # Implements a strategy for evaluating a block over an enumerable to
      # return an array of results. Each fiber consumes and computes greedily
      # until it encounters a deferred realization and yields control. In its
      # place, the strategy creates a new fiber to pick up where the last left
      # off. Proxies are substituted for unrealized values.
      #
      # Profiling shows the mapper strategy is the hotest hot spot in the code.
      # Its methods account for 40% of self time in the nested mapping
      # benchmark. Eek. Steps were taken to reduce this. While this was a huge
      # win for performance, it had the effect of making the code much harder
      # to read. There ain't no such thing as a free lunch.
      class Mapper < Base
        attr_reader :enumerable
        attr_reader :results

        # Initializes a new instance for mapping map_proc over enumerable.
        def initialize(context, enumerable, &map_proc)
          super(context)
          raise ArgumentError, "No block given" unless block_given?
          @enumerable = enumerable
          @map_proc = map_proc

          @consumer = ::Enumerator.new(enumerable)
          @results = []
          @done = false
        end

        # Evaluates map_proc over the enumerable within a succession of fibers
        # and returns an array of results. If any invocation of map_proc
        # blocks, a proxy object is returned in place of a value.
        def call
          # If we haven't exhausted the enumerable, begin a new fiber.
          next_fiber until done?
          results
        end

        private

        # Begin a new consumer fiber. Each fiber is responsible for either:
        #
        #   1) Appending a value to the end of the results array, or
        #   2) Terminating quietly after blocking on a deferred value.
        #
        # In the case of blocking on a deferred value (2), control will have
        # yielded back to #next_fiber and the strategy will have substituted a
        # proxy. Upon resuming, the fiber cannot complete any more iterations
        # because the strategy isn't guaranteed be its parent fiber. The fiber
        # detects this condition with the did_proxy attribute and terminates.
        def next_fiber
          # Initialize local state. These instance variables will be shared
          # with the fiber created in this scope and it alone.
          object = value = target = nil
          has_value = did_proxy = false

          # Start execution in the fiber at (1).
          context.begin_fiber do
            # Greedily consume objects from the enumerable until we run out, or
            # we know that evaluating the iterator blocked and substituted a proxy.

            # (1) Iterate until we run out of objects. Each iteration will add a
            # new object to the results by either #emit_value or #emit_proxy.
            loop do
              begin
                # Consume a new object from the enumerable. If there are no elements
                # remaining, it raises StopIteration and proceeds to (2).
                object = @consumer.next
                # Each result value of the mapper is unique and is referenced by a
                # distinct target constructed from the instance and the index.
                target = Target.new(self, results.length)
              rescue => e
                # (2) The enumeration is complete. Return a nil iterator.
                @done = true
                break
              end

              has_value = false
              did_proxy = false

              # Evaluate map_proc with call. If the proc attempts to realize
              # a deferred value, the invocation will not return immediately and
              # instead transfer control to (3).
              value = @map_proc.call(object)
              has_value = true

              # (4) After reaching here, it might be the case that we returned a
              # proxy to the result. Just saying.

              # If the parent fiber didn't emit a proxy, we're responsible for
              # appending the new value to the results.
              @results << value if !did_proxy
              # It might be the case that we returned a proxy to the result. We
              # should know this from did_proxy. However, for transparency and
              # consistency, we always dispatch the computed value to the context.
              # This resolves the proxy, releases any fibers blocked on it and
              # allows us to trace the event.
              context.dispatch(target, value)

              # If we proxied the last iteration, this fiber has completed its
              # responsibilities and another fiber has continued the enumeration.
              # If this is case, terminate immediately.
              break if did_proxy
            end
          end

          # (3) The fiber returned control. If enumeration is complete, stop.
          return if done?

          # If the last iteration has no value, it's now our responsibility to
          # emit a proxy for the result. In that case, after realization,
          # control will return to (4).
          if !has_value
            # Substitutes a proxy for the given iterator.
            did_proxy = true

            # Returns a proxy to the result of the given iterator. If an attempt is
            # made to resolve the subject outside of a managed fiber, the strategy
            # will call the context to finalize all outstanding events, releasing
            # the dependency on the strategy's fiber. After finalizing, the value
            # must be available, so return it as the subject.
            @results << context.proxy(target) do
              context.finalize!
              # The proxy accepts the returned value as its resolved subject.
              value
            end
          end
        end

        # Returns true when enumeration is complete.
        def done?
          @done
        end
      end
    end
  end
end