require 'xe/realizer/base'
require 'xe/realizer/block'

module Xe
  module Realizer
    # Returns a realizer instance that loads from a block.
    def self.new(tag=nil, &block)
      Realizer::Block.new(tag, &block)
    end
  end
end
