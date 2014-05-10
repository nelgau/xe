module Xe
  class Enumerator
    module Strategy
      # Implements a strategy for evaluating a block over an enumerable to
      # return an array of results. Each fiber consumes and computes greedily
      # until it encounters a deferred realization and yields control. In its
      # place, the strategy creates a new fiber to pick up where the last left
      # off. Proxies are substituted for unrealized values.
      class Mapper < Base
        attr_reader :enumerable
        attr_reader :results

        # Respresents the operation of mapping a single value. If the strategy
        # substituted a proxy for a value, the did_proxy attribute is true.
        Iterator = Struct.new(
          :object,
          :target,
          :did_proxy,
          :has_value,
          :value
        )

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
          # Start execution in the fiber at (1).
          context.begin_fiber { consume }
          # (3) The fiber returned control. If enumeration is complete, stop.
          return if done?
          # If the last iteration has no value, it's now our responsibility to
          # emit a proxy for the result. In that case, after realization,
          # control will return to (4).
          emit_proxy(@last_iter) if !@last_iter.has_value
        end

        # Greedily consume objects from the enumerable until we run out, or
        # we know that evaluating the iterator blocked and substituted a proxy.
        def consume
          # (1) Iterate until we run out of objects. Each iteration will add a
          # new object to the results by either #emit_value or #emit_proxy.
          while (iter = next_iterator)
            # Evaluate the iterator.
            evaluate(iter)
            # If we proxied the last iteration, this fiber has completed its
            # responsibilities and another fiber has continued the enumeration.
            # If this is case, terminate immediately.
            break if iter.did_proxy
          end
        end

        # Evaluates an iterator with map_proc and emits the value.
        def evaluate(iter)
          # Evaluate map_proc with call. If the proc attempts to realize
          # a deferred value, the invocation will not return immediately and
          # instead transfer control to (3).
          value = @map_proc.call(iter.object)
          # (4) After reaching here, it might be the case that we returned a
          # proxy to the result. Just saying.
          emit_value(iter, value)
        end

        # Returns an iterator instance representing the current index. If the
        # consumer is exhausted, this method sets done to true and returns nil.
        def next_iterator
          # Consume a new object from the enumerable. If there are no elements
          # remaining, it raises StopIteration and proceeds to (2).
          object = @consumer.next
          # Each result value of the mapper is unique and is referenced by a
          # distinct target constructed from the instance and the index.
          target = Target.new(self, results.length)
          # Construct a new iterator, assign it to @last_iter and return it.
          return (@last_iter = Iterator.new(object, target, false))
        rescue StopIteration
          # (2) The enumeration is complete. Return a nil iterator.
          @done = true
          nil
        end

        # Returns true when enumeration is complete.
        def done?
          @done
        end

        # Accepts a new value for the iterator.
        def emit_value(iter, value)
          # Set the iterator's value.
          iter.value = value
          iter.has_value = true
          # If the parent fiber didn't emit a proxy, we're responsible for
          # appending the new value to the results.
          @results << value if !iter.did_proxy
          # It might be the case that we returned a proxy to the result. We
          # should know this from did_proxy. However, for transparency and
          # consistency, we always dispatch the computed value to the context.
          # This resolves the proxy, releases any fibers blocked on it and
          # allows us to trace the event.
          context.dispatch(iter.target, value)
        end

        # Substitutes a proxy for the given iterator.
        def emit_proxy(iter)
          iter.did_proxy = true
          @results << proxy(iter)
        end

        # Returns a proxy to the result of the given iterator. If an attempt is
        # made to resolve the subject outside of a managed fiber, the strategy
        # will call the context to finalize all outstanding events, releasing
        # the dependency on the strategy's fiber. After finalizing, the value
        # must be available, so return it as the subject.
        def proxy(iter)
          context.proxy(iter.target) do
            context.finalize!
            # The proxy accepts the returned value as its resolved subject.
            iter.value
          end
        end
      end
    end
  end
end
