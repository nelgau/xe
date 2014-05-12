module Xe
  module Profile
    module Benchmark
      class DrunkWalk < Base
        register_as :drunk_walk

        def call
          Xe.context do
            # Returns a single unrealized value that expands into a very large
            # tree, with each realization yielding more nodes.
            Xe::Test::Realizer::DrunkWalk.start(4)
          end
        end
      end
    end
  end
end
