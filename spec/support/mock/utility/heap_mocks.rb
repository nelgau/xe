module Xe::Test
  module Mock
    module Heap

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
