module Xe::Test
  module Mock
    module Realizer
      module Id
        def new_value_mock(id)
          Value.new(id)
        end

        class Value
          attr_reader :id
          attr_reader :id2

          def initialize(id)
            @id = id
            @id2 = id + 1
          end
        end
      end
    end
  end
end
