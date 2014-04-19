module Xe::Test
  module Enumeration
    module Runner
      class Base
        attr_reader :root
        attr_reader :options

        def self.run!(root, options={})
          new(root, options).run
        end

        def initialize(root, options={})
          @root = root
          @options = options
        end

        def run
          run_unit(root)
        end

        def map(realizer, enum)
          raise NotImplementedError
        end

        private

        # Map over the nested enumerations.
        def run_unit(unit)
          map(unit.realizer, run_items(unit.items))
        end

        # Return an enumerable of the nested enumerations.
        def run_items(items)
          unit?(items) ?
            # Chained enumeration.
            run_chained_unit(items) :
            # Otherwise, treat it as an Enumerable.
            items.flat_map { |x| unit?(x) ? run_unit(x) : x }
        end

        # This method exists purely for instrumentation.
        def run_chained_unit(unit)
          run_unit(unit)
        end

        def unit?(obj)
          obj.is_a?(Unit)
        end
      end
    end
  end
end
