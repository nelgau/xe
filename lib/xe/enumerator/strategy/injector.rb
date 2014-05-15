module Xe
  class Enumerator
    module Strategy
      # Implements a strategy for folding a block over an enumerable starting
      # with an initial value. The result of each invocation (possibly a proxy)
      # is threaded into the next. This chain of proxies pattern allows each
      # block to begin execution immediately while still preserving the
      # serialization of the accumulated result.
      class Injector < Base
        attr_reader :enumerable
        attr_reader :inject_proc

        def initialize(context, enumerable, initial, &inject_proc)
          raise ArgumentError, "No block given" unless block_given?
          super(context)

          @enumerable = enumerable
          @inject_proc = inject_proc
          @result = initial

          @worker = Worker.new(
            @context,
            @enumerable,
            :compute_proc => method(:compute),
            :results_proc => method(:set_result)
          )
        end

        # Evaluates inject_proc as a fold over the enumerable within a
        # succession of fibers and returns the result. If any invocation of
        # inject_proc blocks, a proxy object is returned in place of a value
        # and passed into the next invocation.
        def call
          @worker.call
          @result
        end

        private

        def compute(obj)
          @inject_proc.call(@result, obj)
        end

        def set_result(obj)
          @result = obj
        end
      end
    end
  end
end
