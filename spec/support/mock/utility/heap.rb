module Xe::Test
  module Mock
    module Heap
      # Returns a new comparable object with an interval value.
      def new_value_mock(internal)
        Value.new(internal)
      end

      class Value < Struct.new(:internal)
        include Comparable
        def <=>(other)
          internal <=> other.internal
        end
      end

    end
  end
end
