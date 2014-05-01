module Xe
  module Logger
    class Base
      def call(type, *args)
        send(type, *args)
      end

      private

      def event_realize(event); end

      def value_cached(target); end
      def value_deferred(target); end
      def value_dispatched(target); end
      def value_realized(target); end
      def value_forced(target); end

      def fiber_new; end
      def fiber_wait(target); end
      def fiber_release(target, count); end

      def proxy_new(target); end
      def proxy_resolve(target, count); end

      def finalize_start; end
      def finalize_step(event); end
      def finalize_deadlock; end
    end
  end
end
