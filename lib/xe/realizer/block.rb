module Xe
  module Realizer
    class Block < Base
      def initialize(&call_blk)
        @call_blk = call_blk
      end

      def call(key, group)
        @call_blk.call(key, group)
      end
    end
  end
end
