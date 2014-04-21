module Xe
  class Context
    class Cache
      def initialize
        @cached = {}
      end

      def get(realizer, id)
        [false, nil]
      end

      def set(realizer, id, value)
        return
      end
    end
  end
end
