module Zg
  class Enumerator
    module Provider

      class Base
        attr_reader :context
        attr_reader :enum

        def initialize(context, enum)
          @context = context
          @enum = enum
          @result = nil
        end

        def items
          @items ||= enum.to_a
        end
      end

    end
  end
end
