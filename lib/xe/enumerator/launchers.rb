module Xe
  class Enumerator
    # Convenience methods for invoking the enumeration strategies, or choosing
    # to short-circuit in favor of the standard enumerable methods when the
    # context is disabled.
    module Launchers
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
