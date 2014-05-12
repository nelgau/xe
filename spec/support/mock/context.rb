module Xe::Test
  module Mock
    module Context
      def new_realizer_mock(increment)
        Realizer.new(increment)
      end

      class Realizer < Xe::Realizer::Base
        attr_reader :increment
        attr_reader :performs

        def initialize(increment)
          @increment = increment
          @performs = []
        end

        def perform(group, key)
          @performs << [group, key]
          group.each_with_object({}) do |id, results|
            results[id] = value_for_id(id)
          end
        end

        def clear
          @performs.clear
        end

        def value_for_id(id)
          id + increment
        end
      end
    end
  end
end
