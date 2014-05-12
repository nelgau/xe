module Xe::Test
  module Enumeration
    # Factory for random enumeration topology. The strategy used is entirely
    # deterministic. Building from two factories with the same seed will
    # produce identical topologies.
    class Random
      attr_reader :seed
      attr_reader :max_depth
      attr_reader :max_length
      attr_reader :max_value
      attr_reader :p_chain
      attr_reader :p_branch

      DEFAULT_OPTIONS = {
        :max_depth  => 4,   # Depth of the deepest unit.
        :max_length => 10,  # Length of each unit.
        :max_value  => 50,  # Maximum initial value.
        :p_chain    => 0.5, # Probability that a unit is chained.
        :p_branch   => 0.4  # Probability that an item is a sub-enumeration.
      }

      def self.build(options)
        new(options).build
      end

      def initialize(options={})
        options = DEFAULT_OPTIONS.merge(options)

        @seed       = options[:seed]
        @max_depth  = options[:max_depth]
        @max_value  = options[:max_value]
        @max_length = options[:max_length]
        @p_chain    = options[:p_chain]
        @p_branch   = options[:p_branch]

        initialize_random
      end

      def build
        construct_unit(max_depth)
      end

      private

      def construct_unit(depth=1)
        realizer = Xe::Test::Realizer.generic.sample
        enum = construct_enum(depth - 1)
        Unit.new(realizer, enum)
      end

      def construct_enum(depth=0)
        if depth > 0 && chain?
          construct_unit(depth)
        else
          (0...max_length).map do
            (depth > 0 && branch?) ?
              construct_unit(depth) :
              random_value
          end
        end
      end

      def initialize_random
        @seed ||= Time.now.to_f.hash
        @random = ::Random.new(@seed)
      end

      def random_value
        @random.rand(max_value)
      end

      def chain?
        @random.rand < p_chain
      end

      def branch?
        @random.rand < p_branch
      end
    end
  end
end

