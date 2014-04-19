module Zg
  class Enumerator
    module Provider

      class Map

        def initialize(context, enum)
          super
        end

        def map(&block)
          @result = []
          fibers = enum.map do |o|
            results << nil
            Fiber.new do
              results << block.call(o)
            end
          end
          fibers.each(&:resume)
        end

      end

    end
  end
end
