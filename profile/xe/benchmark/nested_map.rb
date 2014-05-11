module Xe
  module Benchmark
    # This is a totally unfair benchmark that in no way shape or form
    # represents the intended use of the library. However, it does reveal some
    # interesting hotspots, namely iterator creation and hashing.
    class NestedMap < Base
      register_as :nested_map

      ARRAY_SIZE = 100
      VALUE_RANGE = 1000
      MAX_FIBERS = 100
      REALIZER_COUNT = 3

      def initialize
        @enumerable = construct_enumerable
        @realizers  = construct_realizers
        @index = 0
      end

      def call
        Xe.context(max_fibers: MAX_FIBERS) do |c|
          c.enum(@enumerable).map do |xs|
            c.enum(xs).map do |x|
              @index = (@index + 1) % REALIZER_COUNT
              @realizers[@index][x]
            end
          end
        end
      end

      private

      def construct_enumerable
        (0...ARRAY_SIZE).map do |i1|
          (0...ARRAY_SIZE).map do |i2|
            Random.rand(VALUE_RANGE)
          end
        end
      end

      def construct_realizers
        (0...REALIZER_COUNT).map do |i|
          Xe.realizer do |enum|
            enum.each_with_object({}) do |i, h|
              h[i] = i.to_i + 1
            end
          end
        end
      end
    end
  end
end
