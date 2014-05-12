require 'support/realizer/generic'
require 'support/realizer/torture'

module Xe::Test
  module Realizer
    # List of all realizers intended for generic tests. They accept integers or
    # strings as arguments and return integers and strings as realized values.
    # Therefore, it's possible to construct arbitrary topologies without
    # worrying about types.
    def self.generic
      @generic ||= [
        TypeIntToStr.new,
        TypeStrToInt.new,
        Increment.new(1),
        Multiply.new(2),
        Concatenate.new('1')
      ]
    end

    # List of realizers that push the concept of Xe to its limits. These tests
    # are designed to flush out discrepancies between serial and concurrent
    # execution, especially in the case of realizers returning deferred values.
    def self.torture
      @torture ||= [
        DrunkWalk.for_depth(5),
      ]
    end
  end
end
