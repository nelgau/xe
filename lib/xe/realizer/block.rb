module Xe
  module Realizer
    class Block < Base
      attr_reader :tag

      def initialize(tag=nil, &call_blk)
        @tag = tag
        @call_blk = call_blk
      end

      def call(group)
        @call_blk.call(group)
      end

      def inspect
        "#<#{self.class.name}#{tag && "(#{tag})"}>"
      end
    end
  end
end
