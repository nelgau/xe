module Xe
  class Enumerator
    module Strategy
      # Implements a strategy for folding a block over an enumerable starting
      # with an initial value. The result of each invocation (possibly a proxy)
      # is threaded into the next. This chain of proxies pattern allows each
      # block to begin execution immediately while still preserving the
      # serialization of the accumulated result.
      class Injector < Base
        attr_reader :enum
        attr_reader :inject_proc

        def initialize(context, enum, initial, options={}, &inject_proc)
          raise ArgumentError, "No block given" unless block_given?
          super(context, options)

          @enum = enum
          @inject_proc = inject_proc
          @initial = initial
          @last_result = initial

          @worker = Worker.new(
            @context,
            @enum,
            :compute_proc => method(:compute),
            :results_proc => method(:set_last_result),
            :tag => :injector
          )
        end

        # Evaluates inject_proc as a fold over the enumerable within a
        # succession of fibers and returns the result. If any invocation of
        # inject_proc blocks, a proxy object is returned in place of a value
        # and passed into the next invocation.
        def perform
          @worker.call
          @last_result
        end

        # Evaluates inject_proc as a fold over the enumerable immediately
        # and returns the result.
        def perform_serial
          @enum.inject(@initial, &@inject_proc)
        end

        private

        def compute(object, index)
          @inject_proc.call(@last_result, object)
        end

        def set_last_result(value, object)
          @last_result = value
        end
      end
    end
  end
end
