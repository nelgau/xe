module Xe
  class Enumerator
    module Implementation

      # The Big Three

      # Invokes the block once for each element in the enumerable. Returns a
      # new array of all the elements.
      def each(&blk)
        run_mapper { |o| blk.call(o); o }
      end

      # Returns a new array from the results of running the block once for each
      # element in the enumerable. Substitutes proxies for unrealized values.
      def map(&blk)
        run_mapper(&blk)
      end

      # Returns the result of folding a block over the enumerable starting with
      # the given initial value.
      def inject(initial, &blk)
        run_injector(initial, &blk)
      end

      # Injection-like

      def each_with_object(obj, &blk)
        run_injector(obj) { |acc, o| blk.call(o, acc); acc }
      end

      private

      # Runs a computation, returning a value, within a single fiber. If the
      # fiber blocks on a realization, a proxy is returned instead.
      def run_evaluator(&blk)
        # Serialize execution when the context is disabled.
        return blk.call if !context.enabled?
        Strategy::Evaluator.(context, &blk)
      end

      # Runs an enumeration, returning an array of independent values, within a
      # succession of fibers. If some fiber blocks on a realization, a proxy is
      # substituted for that value.
      def run_mapper(&blk)
        # Serialize execution when the context is disabled.
        return enumerable.map(&blk) if !context.enabled?
        Strategy::Mapper.(context, enumerable, &blk)
      end

      # Runs an enumeration, returning a value, with a succession of fibers,
      # that folds a block starting with the given initial value. If some fiber
      # blocks on a realization, a proxy is substituted for that value and
      # passed into the next iteration.
      def run_injector(initial, &blk)
        # Serialize execution when the context is disabled.
        return enumerable.inject(initial, &blk) if !context.enabled?
        Strategy::Injector.(context, enumerable, initial, &blk)
      end
    end
  end
end
