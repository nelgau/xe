require 'thread'

module Xe
  class Context
    # This song and dance is necessary because Ruby's "thread-local" variables
    # are in reality fiber-local. We can't store the current context there.
    module Current
      def all_contexts
        @all_contexts ||= {}
      end

      def current
        all_contexts[current_thread_key]
      end

      def current=(context)
        all_contexts[current_thread_key] = context
      end

      def clear_current
        all_contexts.delete(current_thread_key)
      end

      def current_thread_key
        Thread.current.object_id
      end
    end
  end
end
