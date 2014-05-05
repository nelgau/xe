module Xe::Test
  module Enumeration
    module Runner
      class Context < Base

        # Wrap execution in a Xe context.
        def run
          Xe.context(options) { super }
        end

        # Runs the realizer using a Xe enumeration, within a context.
        def map(realizer, enum)
          Xe.map(enum) { |x| realizer[x] }
        end
      end
    end
  end
end
