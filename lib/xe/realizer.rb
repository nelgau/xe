require 'xe/realizer/base'
require 'xe/realizer/cacheable'
require 'xe/realizer/proc'
require 'xe/realizer/id'

module Xe
  module Realizer
    # Returns a realizer instance that loads values from a proc. You can pass
    # the `tag` option to make your realizers easier to differentiate.
    def self.new(tag=nil, &proc)
      Realizer::Proc.new(tag, &proc)
    end
  end
end
