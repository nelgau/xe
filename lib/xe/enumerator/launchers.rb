module Xe
  class Enumerator
    # Convenience methods for invoking the enumeration strategies, or choosing
    # to short-circuit in favor of the standard enumerable methods when the
    # context is disabled.
    module Launchers
      # Runs a computation, returning a value, within a single fiber. If the
      # fiber blocks on a realization, a proxy is returned instead.
      def run_evaluator(&blk)
        Strategy::Evaluator.(context, options, &blk)
      end

      # Runs an enumeration, returning a value, with a succession of fibers,
      # that folds a block starting with the given initial value. If some fiber
      # blocks on a realization, a proxy is substituted for that value and
      # passed into the next iteration.
      def run_injector(initial, &blk)
        Strategy::Injector.(context, enum, initial, options, &blk)
      end

      # Runs an enumeration, returning an array of independent values, within a
      # succession of fibers. If some fiber blocks on a realization, a proxy is
      # substituted for that value.
      def run_mapper(&blk)
        Strategy::Mapper.(context, enum, options, &blk)
      end
    end
  end
end
