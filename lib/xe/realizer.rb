require 'xe/realizer/base'
require 'xe/realizer/block'

module Xe
  module Realizer
    # Returns a realizer instance that loads from a block.
    def self.new(&block)
      Realizer::Block.new(&block)
    end
  end
end
