module Xe::Test
  module Realizer
    class Concatenate < Xe::Realizer::Base
      attr_reader :string

      def initialize(string='')
        @string = string
      end

      # Map the values to their string representation with a constant suffix.
      def perform(enum)
        enum.each_with_object({}) do |i, h|
          h[i] = i.to_s + string
        end
      end
    end
  end
end
