module Xe::Test
  module Enumeration
    module Runner
      class Immediate < Base
        # Runs the realizer sequentially and immediately, without a context.
        def map(realizer, enum)
          enum.map { |x| realizer[x] }
        end
      end
    end
  end
end
