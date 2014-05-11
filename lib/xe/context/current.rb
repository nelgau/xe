require 'thread'

module Xe
  class Context
    # This song and dance is necessary because Ruby's "thread-local" variables
    # are in reality fiber-local. We can't store the current context there.
    module Current
      # Returns a hash mapping thread identifiers to contexts.
      def all_contexts
        @all_contexts ||= {}
      end

      # Returns the current context for this thread, or nil if none exists.
      def current
        all_contexts[Thread.current.object_id]
      end

      # Assigns a context instance to the current thread.
      def current=(context)
        all_contexts[Thread.current.object_id] = context
      end

      # Clears the assigned context for the current thread.
      def clear_current
        all_contexts.delete(Thread.current.object_id)
      end
    end
  end
end
