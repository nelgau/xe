module Xe
  class Enumerator
    class Proxy < Xe::Proxy
      attr_reader :__context
      attr_reader :__target

      def initialize(context, target, force_proc)
        super()
        @__context = context
        @__target = target
        @__force_proc = force_proc
      end

      # If the receiver doesn't have a subject, set it using the realization
      # procedure passed to the initializer. Returns the receiver's subject.
      def __resolve_subject
        return @__subject if @__has_subject
        new_subject = @__context.wait(@__target, @__force_proc)
        __set_subject(new_subject)
      end

      def __invalidate!
        @__context = nil
        @__target = nil
        @__force_proc = nil
      end

      def __xe_proxy_name
        "Xe::Enumerator::Proxy"
      end
    end
  end
end
