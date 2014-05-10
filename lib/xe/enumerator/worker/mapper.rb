module Xe
  class Enumerator
    module Worker
      class Mapper < Base
        attr_reader :enumerable
        attr_reader :results

        # Used to share state between the run method and the next invocation
        # of #proxy! when the fiber is suspended. In the case of the immediate
        # resolution of the proxy, it will fetch the result from here.
        Iteration = Struct.new(:target, :did_proxy, :result)

        def initialize(enumerable, &map_proc)
          raise ArgumentError, "No block given" unless block_given?
          @enumerable = enumerable
          @map_proc = map_proc

          @consumer = ::Enumerator.new(enumerable)
          @results = []
          @done = false
        end

        def done?
          @done
        end

        def run
          object = @consumer.next
          target = Target.new(self, results.length)

          # Create a new item in the results array with a temporary value
          # and store the index of this position. If the computation can't
          # be realized immediately, this temporary value will be replaced
          # by a proxy with (2).
          results << nil

          current_iter = Iteration.new(target, false)
          @last_iter = current_iter

          result = @map_proc.call(object)

          current_iter.result = result
          context.dispatch(target, result)

          unless current_iter.did_proxy
            results[target.id] = result
          end

        rescue StopIteration
          @done = true
        end

        def proxy!
          current_iter = @last_iter
          target = current_iter.target
          current_iter.did_proxy = true

          results[target.id] = context.proxy(target) do
            context.finalize!
            current_iter.result
          end
        end










        # def blah
        #   loop do
        #     # Although the body of this process may occur across many fibers,
        #     # each iteration of the loop is serialized. Therefore, it must
        #     # consume objects and assign result indexes in serial order.

        #     break if index >= enum.length

        #     # Consume a single object.
        #     object = enum[index]
        #     object_index = index
        #     index += 1

        #     # Create a new item in the results array with a temporary value
        #     # and store the index of this position. If the computation can't
        #     # be realized immediately, this temporary value will be replaced
        #     # by a proxy with (2).
        #     results << nil

        #     # Create a new target for this index.
        #     target = Target.new(self, index)

        #     # Run the computation. If the block attempts to realize a
        #     # deferred value, execution of the fiber will suspend inside of
        #     # it and resume with the result value when it becomes available.
        #     # When execution suspends, control returns to (1).
        #     result = object + 1

        #     # (3) Once the result of the computation is known, dispatch the
        #     # value to any unresolved proxies and waiting fibers. Due to the
        #     # isolation between values and targets, this will never cause the
        #     # current fiber to suspend execution.
        #     context.dispatch(target, result)

        #     # If this fiber returned control to the enclosing method, we
        #     # are not responsible for continuing the enumeration. Break
        #     # out of the loop immediately. Control returns to (1).
        #     break if suspended

        #     # As the fiber never suspended, it is responsible for storing
        #     # the result of the computation at the given index.
        #     results[object_index] = result
        #   end

        # ensure
        #   context.fiber_started
        # end




            # last_index = mapper.index

            # Signal to the fiber that it's no longer responsible for the
            # remainder of the enumeration and that it should terminate after
            # dispatching the result of its last computation.
            # mapper.suspended!

            # (2) As the fiber has yet to terminate, the result of the
            # computation is unknwown at this time. Create a new proxy for the
            # target. Resolving this proxy in a managed fiber will suspend
            # execution until the above fiber dispatches its result with (3).
            # all_results[last_index] = context.proxy(target) do
              # The proxy was realized in an unmanaged fiber so we can't wait
              # for the value to be available. We must finalize the context.
              # This necessarily releases all fibers (or deadlocks). So
              # assuming the operation succeeds, the result must be available.
              # context.finalize
              # The proxy's subject is just the result.
              # mapper.results[last_index]
            # end
          # end


      end
    end
  end
end
