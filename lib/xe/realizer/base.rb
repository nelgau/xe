require 'set'

module Xe
  module Realizer
    class Base < Deferrable
      # Returns a proxy for a realized value with the given id, creating a
      # singleton instance of the realizer is none yet exists. As common
      # realizer subclasses are likely to be fully stateless, this is the
      # preferred shorthand for deferrals.
      def self.[](id)
        (@default ||= new)[id]
      end

      # Returns a proxy for a realized value with the given id.
      def [](id)
        # Block on the realization of the id. This enforces isolation between
        # values (which can be proxied and lazily realized) and the manner
        # by which they are referenced (ids, targets and events).
        id = Proxy.resolve(id)
        key = group_key(id)
        # If an active context is available, defer the evaluation of this id.
        # Otherwise, realize the value immediately.
        Context.active? ?
          Context.current.defer(self, id, key) :
          call([id])[id]
      end

      # Override these methods to implement a realizer.

      # Override this method to provide a batch loader.
      # Returns a map from group members to values. The group argument may be
      # of the type returned by the #new_group method, or it may be an
      # arbitrary object instance that conforms to the Enumerable interface.
      # The latter is the case when a client attempts to defer the realization
      # of a value with no active context.
      def perform(group)
        raise NotImplementedError
      end

      # Override this method to specify a key by which to group this id. Each
      # unique key will result in a unique group created by #new_group method.
      # Returns a key that will be used to group ids into batches.
      def group_key(id)
        nil
      end

      # Override this method to return a container for accumulating ids.
      # Returns a new enumerable than responds to :<<.
      def new_group(key)
        Set.new
      end

      # This method is overriden in subclasses to customize the sematics of the
      # return values from #perform. The default implementation is passthrough.
      def call(group)
        perform(group)
      end

      def inspect
        "#<#{self.class.name}>"
      end

      def to_s
        inspect
      end
    end
  end
end
