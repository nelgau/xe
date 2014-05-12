module Xe::Test
  module Mock
    module Proxy

      def new_value_mock(internal)
        Value.new(internal)
      end

      class Value
        attr_reader :internal

        def initialize(internal=nil)
          @internal = internal
        end

        def ==(other)
          return false if !other.is_a?(Value)
          @internal == other.internal
        end

        def eql?(other)
          self == other
        end

        def hash
          @internal.hash
        end

        def foo(*args, &blk)
        end

        def bar(*args, &blk)
        end
      end

    end
  end
end
