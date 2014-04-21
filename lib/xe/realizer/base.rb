require 'set'

module Xe
  module Realizer
    class Base
      # Returns a proxy for the realized value.
      def self.[](id)
        (@default ||= new)[id]
      end

      # Returns a proxy for the realized value.
      def [](id)
        context = Xe::Context.current
        context ? context.defer(self, id) : load_id(id)
      end

      # Override these methods to implement a realizer.

      # Override this method to provide a batch loader.
      # Returns a map from group members to values.
      def call(group_key, group)
        raise NotImplementedError
      end

      # Override this method to specify keys with which to group ids.
      # Returns a key that will be used to group ids into batches.
      def group_key_for_id(id)
        :default
      end

      # Override this method to return a container for accumulating ids.
      # Returns a new container than responds to :<<.
      def new_group(key)
        Set.new
      end

      private

      # This method exists purely to support the case in which a realizer is
      # called outside of a context. This is unlikely to ever be the case in
      # production code but we still support it.
      def load_id(id)
        group_key = group_key_for_id(id)
        group = new_group(group_key)
        group << id
        self.call(group_key, group)[id]
      end
    end
  end
end
