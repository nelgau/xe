module Xe::Test
  module Enumeration
    module Runner
      class Standard < Base
        # Runs the realizer's #call method directly.
        def map(realizer, enum)
          results = realizer.call(enum, nil)
          enum.map { |x| results[x] }
        end
      end
    end
  end
end
