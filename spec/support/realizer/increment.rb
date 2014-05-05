module Xe::Test
  module Realizer
    class Increment < Xe::Realizer::Base
      attr_reader :count

      def initialize(count=1)
        @count = count
      end

      # Map the values to their integer value incremented by a constant.
      def perform(enum)
        enum.each_with_object({}) do |i, h|
          h[i] = i.to_i + count
        end
      end
    end
  end
end
