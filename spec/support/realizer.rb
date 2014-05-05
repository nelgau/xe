require 'support/realizer/type_int_to_str'
require 'support/realizer/type_str_to_int'
require 'support/realizer/multiply'

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
        Multiply.new(2),
        Multiply.new(4)
      ]
    end
  end
end
