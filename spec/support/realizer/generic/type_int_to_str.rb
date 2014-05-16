module Xe::Test
  module Realizer
    class TypeIntToStr < Xe::Realizer::Base
      # Map the values to their string representations.
      def perform(enum, key)
        enum.each_with_object({}) do |i, h|
          h[i] = i.to_s
        end
      end
    end
  end
end
