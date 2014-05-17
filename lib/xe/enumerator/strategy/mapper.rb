module Xe
  class Enumerator
    module Strategy
      # Implements a strategy for evaluating a block over an enumerable to
      # return an array of results.
      class Mapper < Base
        attr_reader :enum
        attr_reader :map_proc
        attr_reader :results

        def initialize(context, enum, &map_proc)
          raise ArgumentError, "No block given" unless block_given?
          super(context)

          @enum = enum
          @map_proc = map_proc
          @results = []

          @worker = Worker.new(
            @context,
            @enum,
            :compute_proc => map_proc,
            :results_proc => method(:add_result)
          )
        end

        # Evaluates map_proc over the enumerable within a succession of fibers
        # and returns an array of results. If any invocation of map_proc
        # blocks, a proxy object is returned in place of a value.
        def perform
          @worker.call
          @results
        end

        # Evaluates map_proc over the enumerable and returns the result.
        def perform_serial
          @enum.each_with_index.map(&@map_proc)
        end

        private

        def add_result(value, object)
          @results << value
        end
      end
    end
  end
end
