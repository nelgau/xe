module Xe
  module Profile
    module Benchmark
      class NestedInject < Base
        register_as :inject

        ARRAY_SIZE = 500
        VALUE_RANGE = 1000
        REALIZER_COUNT = 3
        MAX_FIBERS = 25

        def self.description
          "Nested Xe.enum().inject over #{ARRAY_SIZE ** 2} values " \
          "with #{VALUE_RANGE} IDs and #{REALIZER_COUNT} realizers.\n" \
          "The context uses a maximum of #{MAX_FIBERS} fibers."
        end

        def initialize
          @enumerable = construct_enumerable
          @realizers  = construct_realizers
          @index = 0
        end

        def call
          Xe.context(:max_fibers => 100) do |c|
            c.enum(@enumerable).inject(0) do |sum, xs|
              sum + c.enum(xs).inject(0) do |sum2, x|
                @index = (@index + 1) % REALIZER_COUNT
                sum2 + @realizers[@index][x]
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
