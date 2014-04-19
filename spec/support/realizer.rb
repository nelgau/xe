require 'support/realizer/type_int_to_str'
require 'support/realizer/type_str_to_int'
require 'support/realizer/increment'
require 'support/realizer/multiply'
require 'support/realizer/concatenate'

module Xe::Test
  module Realizer
    # List of all realizers intended for generic tests. They accept integers or
    # strings as arguments and return integers and strings as realized values.
    # Therefore, it's possible to construct arbitrary topologies without
    # worrying about types.
    def self.all
      @all ||= [
        TypeIntToStr.new,
        TypeStrToInt.new,
        Increment.new(1),
        Multiply.new(2),
        Concatenate.new('1')
      ]
    end
  end
end
