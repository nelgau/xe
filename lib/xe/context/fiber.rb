module Xe
  class Context

    class Fiber
      attr_reader :context

      def initialize(context, &blk)
        super(&blk)
        @context = context
      end
    end

  end
end
