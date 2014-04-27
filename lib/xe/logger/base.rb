module Xe
  module Logger
    class Base
      def call(event, *args)
        send(event, *args)
      end

      private

      def finalize_start; end
      def finalize_step; end
      def finalize_deadlock; end

      def value_cached(source, id); end
      def value_deferred(source, id); end
      def value_dispatched(source, id); end
      def value_realized(realizer, id); end
      def value_forced(realizer, id); end

      def fiber_new; end
      def fiber_wait(source, id); end
      def fiber_release(source, id, count); end

      def proxy_new(source, id); end
      def proxy_resolve(source, id, proxy_count); end
    end
  end
end
