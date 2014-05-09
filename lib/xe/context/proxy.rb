module Xe
  class Context
    class Proxy < Xe::Proxy
      attr_reader __context
      attr_reader __target

      def initialize(context, target)
        @__context = context
        @__target = target
      end

      # If the receiver doesn't have a subject, set it using the realization
      # procedure passed to the initializer. Returns the receiver's subject.
      def __resolve_subject
        return @__subject if @__has_subject
        waiter_proc = Context::Waiter.build_realize(self, target)
        new_subject = @__context.wait(target, waiter_proc)
        __set_subject(new_subject)
      end

      # Set the subject and drop all references to the resolution procedure.
      # Returns the reciever's subject.
      def __set_subject(subject)
        __invalidate!
        super
      end

      def __invalidate!
        @__context = nil
        @__target = nil
      end
    end
  end
end
