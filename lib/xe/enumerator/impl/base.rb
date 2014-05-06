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

        # Release all references to external objects, allowing them to be
        # garbage-collected even if the enumeration instance outlives them.
        def invalidate!
          @context = nil
          @enum = nil
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

        # For now, the only condition on concurrent execution (with fibers)
        # is the existence of an active, enabled context. In the future,
        # subclasses may override this method to enforce stricter conditions.
        def concurrent?
          context.enabled?
        end

        # The most important idea to keep in mind while reviewing the following
        # code is that, while fibers can be concurrent, the order of any
        # particular set of statements is serializable and fixed over all
        # executions of the same input. I've tried to give clear hints below
        # to demonstrate the paths of execution.

        # Run a computation (returning a single value) within a new managed
        # fiber. If the result blocks on a deferred realization, a proxy for
        # the value is returned instead.
        def run_value(&blk)
          # When serializing, immediately evaluate the block and return.
          return blk.call if !concurrent?

          # Create a reference to the result in the local scope. If we can't
          # defer the realization of the proxy (see below), it will set its
          # subject with this captured reference.
          result = nil

          # Create a new target for this result.
          target = Target.new(self, nil)

          # Start a managed fiber.
          fiber = begin_fiber do |ctx|
            # Run the computation. If the block attempts to realize a deferred
            # value, execution of the fiber will suspend inside of it and
            # resume with the result value when it becomes available. When
            # execution suspends, control returns to (1).
            result = blk.call
            # (2) Once the result of the computation is known, dispatch the
            # value to any unresolved proxies and waiting fibers. Due to the
            # isolation between values and targets, this will never cause the
            # current fiber to suspend execution.
            ctx.dispatch(target, result)
          end

          # (1) The fiber has finished executing or is suspended.

          # If the fiber terminated, the result of the computation is known
          # at this time. Return the value to the caller immediately.
          return result if !fiber.alive?

          # Release our reference to the fiber.
          fiber = nil

          # As the fiber has yet to terminate, the result of the computation
          # is unknwown at this time. Create a new proxy for the target.
          # Resolving this proxy in a managed fiber will suspend execution
          # until the above fiber dispatches its result with (2).
          proxy = @context.proxy(target) do |ctx|
            # The proxy was realized in an unmanaged fiber. We can't wait for
            # the value to be available. We must finalize the context. This
            # necessarily releases all fibers (or deadlocks). So assuming the
            # operation succeeds the result must be available.
            ctx.finalize
            # The proxy's subject is just the result.
            result
          end

          # Return a proxied result.
          proxy
        end

        # Run an enumeration (returning an array of independent values) within
        # managed fibers. If some item in the collection blocks on a deferred
        # realization, a proxy is substituted of the result.
        def run_map(&blk)
          results = []
          consumer = ::Enumerator.new(enum)
          # Iteratively create fibers until we exhaust the consumer.
          while run_map_fiber(results, consumer, &blk); end
          results
        end

        # Run many iterations of an enumeration within a single fiber by
        # retrieving values from the consumer and emiting results to the
        # first argument. If a result blocks on the realization of a deferred
        # value, a proxy is substituted and control returns to the caller.
        def run_map_fiber(all_results, consumer, &blk)
          # Initialize the state of the enumeration. This method creates a
          # single fiber and shares its local variables with that fiber alone.

          object = nil       # Current consumed object.
          index  = nil       # Index of the current result value.
          target = nil       # Target of the current result value.
          suspended = false  # Did the fiber suspend execution (by deferring)?
          stop  = false      # Have we exhausted the consumer?

          # Create a reference to the last result in the local scope. If we
          # can't defer the realization of the proxy (see below), it will set
          # its subject with this captured reference.
          result = nil

          # Start a managed fiber.
          fiber = begin_fiber do |ctx|
            loop do
              # Although the body of this process may occur across many fibers,
              # each iteration of the loop is serialized. Therefore, it must
              # consume objects and assign result indexes in serial order.

              # Consume a single object.
              begin
                object = consumer.next
              rescue StopIteration
                # The consumer is empty so enumeration is complete. Set the
                # done flag and break out of the loop. Control returns to (1).
                stop = true
                break
              end

              # Create a new item in the results array with a temporary value
              # and store the index of this position. If the computation can't
              # be realized immediately, this temporary value will be replaced
              # by a proxy with (2).
              index = all_results.length
              all_results << nil

              # Create a new target for this index.
              target = Target.new(self, index)

              # Run the computation. If the block attempts to realize a
              # deferred value, execution of the fiber will suspend inside of
              # it and resume with the result value when it becomes available.
              # When execution suspends, control returns to (1).
              result = blk.call(object)

              # (3) Once the result of the computation is known, dispatch the
              # value to any unresolved proxies and waiting fibers. Due to the
              # isolation between values and targets, this will never cause the
              # current fiber to suspend execution.
              ctx.dispatch(target, result)

              # If this fiber returned control to the enclosing method, we
              # are not responsible for continuing the enumeration. Break
              # out of the loop immediately. Control returns to (1).
              break if suspended

              # As the fiber never suspended, it is responsible for storing
              # the result of the computation at the given index.
              all_results[index] = result
            end
          end

          # (1) The fiber has finished executing or is suspended.

          # If the fiber is still alive, this is its final iteration.
          if fiber.alive?
            # Signal to the fiber that it's no longer responsible for the
            # remainder of the enumeration and that it should terminate after
            # dispatching the result of its last computation.
            suspended = true

            # (2) As the fiber has yet to terminate, the result of the
            # computation is unknwown at this time. Create a new proxy for the
            # target. Resolving this proxy in a managed fiber will suspend
            # execution until the above fiber dispatches its result with (3).
            all_results[index] = context.proxy(target) do |ctx|
              # The proxy was realized in an unmanaged fiber so we can't wait
              # for the value to be available. We must finalize the context.
              # This necessarily releases all fibers (or deadlocks). So
              # assuming the operation succeeds, the result must be available.
              ctx.finalize
              # The proxy's subject is just the result.
              result
            end
          end

          # Release any external references in the local scope.
          object = nil
          fiber = nil

          # If stop is false, the consumer has yet to be exhausted. Ask the
          # caller to continue enumerating in a new fiber.
          !stop
        end

        private

        # Start execution of the given block in a new managed fiber. Pass the
        # current context as the first argument to the block.
        def begin_fiber(&blk)
          fiber = context.fiber(&blk)
          fiber.run(context)
          fiber
        end
      end
    end
  end
end
