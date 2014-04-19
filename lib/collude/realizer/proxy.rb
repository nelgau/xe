module Collude
  class Realizer
    class Proxy < BasicObject
      def initialize(context, realizer_class, args)
        @__context = context
        @__realizer_class = realizer_class
        @__args = args
        @__realized = false

        # Add this proxy to those managed by the context.
        @__context.add_proxy(self)
      end

      protected

      def method_missing(method, *args, &block)
        __realize
        @__value.__send__(method, *args, &block)
      end

      def __realize
        return if @__realized
        @__value = @__context.did_realize(@__realizer_class, @__args)
        @__realized = true
      end
    end
  end
end
