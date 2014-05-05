module Xe::Test
  module Realizer
    class Multiply < Xe::Realizer::Base
      attr_reader :factor

      def initialize(factor=2)
        @factor = factor
      end

      # Map the values to their integer value multiplied by a constant factor
      def perform(enum)
        enum.each_with_object({}) do |i, h|
          h[i] = i.to_i * factor
        end
      end
    end
  end
end
