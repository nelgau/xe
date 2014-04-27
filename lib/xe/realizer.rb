require 'xe/realizer/base'
require 'xe/realizer/block'

module Xe
  module Realizer
    # Returns a realizer instance that loads from a block.
    def self.new(name, &block)
      Realizer::Block.new(name, &block)
    end
  end
end
