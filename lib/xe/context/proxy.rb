module Xe
  class Context
    class Proxy < Xe::Proxy
      attr_reader :__context
      attr_reader :__target

      def initialize(context, target)
        super()
        @__context = context
        @__target = target
      end

      # If the receiver doesn't have a subject, set it using the realization
      # procedure passed to the initializer. Returns the receiver's subject.
      def __resolve_subject
        return @__subject if @__has_subject
        force_proc = Proxy.forced_proc(@__context, @__target)
        new_subject = @__context.wait(@__target, force_proc)
        __set_subject(new_subject)
      end

      def __invalidate!
        @__context = nil
        @__target = nil
      end

      def __xe_proxy_name
        "Xe::Context::Proxy"
      end

      private

      def self.forced_proc(context, target)
        ::Proc.new do
          context.realize_target(target)
        end
      end
    end
  end
end