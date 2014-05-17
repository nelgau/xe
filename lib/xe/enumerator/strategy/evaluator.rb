module Xe
  class Enumerator
    module Strategy
      # Implements a strategy for evaluating a block within a single fiber. If
      # the computation blocks on the realization of a value, the strategy's
      # run method returns a proxy object.
      class Evaluator < Base
        attr_reader :value_proc
        attr_reader :result

        def initialize(context, &value_proc)
          raise ArgumentError, "No block given" unless block_given?
          super(context)

          @value_proc = value_proc
          # Evaluate a single result.
          @enumerable = [nil]
          @result = nil

          @worker = Worker.new(
            context,
            @enumerable,
            :compute_proc => value_proc,
            :results_proc => method(:set_result)
          )
        end

        # Evaluates value_proc within a single fiber and returns the value as
        # the result. If the computation blocks, a proxy object is returned.
        def perform
          @worker.call
          @result
        end

        # Evaluates value_proc immediately and returns the result.
        def perform_serial
          @value_proc.call
        end

        private

        def set_result(value, object)
          @result = value
        end
      end
    end
  end
end
