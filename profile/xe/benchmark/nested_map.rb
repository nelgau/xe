module Xe
  module Profile
    module Benchmark
      # This is a totally unfair benchmark that in no way shape or form
      # represents the intended use of the library. However, it does reveal
      # some interesting hotspots, namely hashing.
      class NestedMap < Base
        register_as :nested_map

        ARRAY_SIZE = 500
        VALUE_RANGE = 1000
        REALIZER_COUNT = 5
        MAX_FIBERS = 50

        def self.description
          "Nested Xe.map over #{ARRAY_SIZE ** 2} values " \
          "with #{VALUE_RANGE} IDs and #{REALIZER_COUNT} realizers.\n" \
          "The context uses a maximum of #{MAX_FIBERS} fibers."
        end

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
end

