module Xe
  class Enumerator
    module Strategy
      # Implements a strategy for evaluating a block over an enumerable to
      # return an array of results.
      class Mapper < Base
        attr_reader :enumerable
        attr_reader :map_proc
        attr_reader :results

        def initialize(context, enumerable, &map_proc)
          raise ArgumentError, "No block given" unless block_given?
          super(context)

          @enumerable = enumerable
          @map_proc = map_proc
          @results = []

          @worker = Worker.new(
            @context,
            @enumerable,
            :compute_proc => map_proc,
            :results_proc => method(:add_result)
          )
        end

        # Evaluates map_proc over the enumerable within a succession of fibers
        # and returns an array of results. If any invocation of map_proc
        # blocks, a proxy object is returned in place of a value.
        def call
          @worker.call
          @results
        end

        private

        def add_result(obj)
          @results << obj
        end
      end
    end
  end
end
