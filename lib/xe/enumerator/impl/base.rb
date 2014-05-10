module Xe
  class Enumerator
    module Impl
      class Base
        attr_reader :enumerable
        attr_reader :tag

        def initialize(enumerable, options={})
          @enumerable = enumerable
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

          # Create a single fiber in which to evaluate the block.
          evaluator = Worker::Evaluator.new(&blk)
          run_proc = evaluator.method(:run)
          fiber = Context.current.begin_fiber(&run_proc)

          fiber.alive? ?
            evaluator.proxy! :
            evaluator.result
        end

        # Run an enumeration (returning an array of independent values) within
        # managed fibers. If some item in the collection blocks on realization,
        # a proxy is substituted for the result.
        def run_map(&blk)
          # When serializing, immediately evaluate the mapping and return.
          return enumerable.map(&blk) if !concurrent?
          return [] if enumerable.empty?

          # Iteratively create fibers until we exhaust the enumerable.
          mapper = Worker::Mapper.new(enumerable, &blk)
          run_proc = mapper.method(:run)

          until mapper.done?
            fiber = Context.current.begin_fiber(&run_proc)
            mapper.proxy! if fiber.alive?
          end

          mapper.results
        end

        # For now, the only condition on concurrent execution (with fibers)
        # is the existence of an active, enabled context. In the future,
        # subclasses may override this method to enforce stricter conditions.
        def concurrent?
          Context.current.enabled?
        end
      end
    end
  end
end
