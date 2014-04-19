module Xe::Test
  module Mock
    module Proxy

      def new_value_mock(internal)
        Value.new(internal)
      end

      class Value < Struct.new(:internal)
        def foo(*args, &blk)
        end

        def bar(*args, &blk)
        end
      end

    end
  end
end
