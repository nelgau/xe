require 'support/realizer'
require 'support/enumeration'

module Xe
  module Profile
    module Benchmark
      class Randomized < Base
        register_as :randomized

        MAX_DEPTH = 9
        MAX_LENGTH = 10
        MAX_FIBERS = 100

        def self.description
          "Randomized nested Xe.map with a depth of #{MAX_DEPTH}, " \
          "a branching factor of #{MAX_LENGTH}.\n" \
          "The context uses a maximum of #{MAX_FIBERS} fibers."
        end

        def initialize
          @build_options = {
            :max_depth  => MAX_DEPTH,
            :max_length => MAX_LENGTH
          }
          @run_options = {
            :max_fibers => MAX_FIBERS
          }

          @factory = Xe::Test::Enumeration::Random.new(@build_options)
          @root = @factory.build
        end

        def call
          Xe::Test::Enumeration.run!(:context, @root, @run_options)
        end
      end
    end
  end
end
