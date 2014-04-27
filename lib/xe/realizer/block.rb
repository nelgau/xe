module Xe
  module Realizer
    class Block < Base
      attr_reader :name

      def initialize(name=nil, &call_blk)
        @name = name || '...'
        @call_blk = call_blk
      end

      def call(key, group)
        @call_blk.call(group)
      end

      def inspect
        "#<#{self.class.name}(#{name})>"
      end
    end
  end
end
