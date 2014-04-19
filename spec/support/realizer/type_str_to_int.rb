module Xe::Test
  module Realizer
    class TypeStrToInt < Xe::Realizer::Base
      # Map the values to their integer representations.
      def perform(enum)
        enum.each_with_object({}) do |i, h|
          h[i] = i.to_i
        end
      end
    end
  end
end
