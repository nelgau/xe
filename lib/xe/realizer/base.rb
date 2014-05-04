require 'set'

module Xe
  module Realizer
    class Base < Deferrable
      # A quick note on passing keys to .[] and #[] --
      #
      #   Smart clients of Realizer::Base may know best how to group
      #   realizations. Since delegating this into the realizer subclass itself
      #   (using group_key) may not be the most effective factoring (to keep
      #   group members trivial, like integers, and push all attributes about
      #   'how' to realize them into the key itself), this interface is
      #   provided for the advanced consumer.

      # Returns a proxy for a realized value with the given id, creating a
      # singleton instance of the realizer is none yet exists. As common
      # realizer subclasses are likely to be stateless, this is the preferred
      # shorthand for deferrals.
      def self.[](id, key=nil)
        (@default ||= new)[id, key]
      end

      # If an active context exists, this method returns a proxy for the
      # realized value with the given id and key. If no key is given, the
      # group_key method will be invoked to provide one.
      def [](id, key=nil)
        # Block on the realization of the id. This enforces isolation between
        # values (which can be proxied and lazily realized) and the manner
        # by which they are referenced (ids, targets and events).
        id = Proxy.resolve(id)
        key ||= group_key(id)
        # If an active context is available, defer the evaluation of this id.
        # Otherwise, realize the value immediately.
        Context.active? ?
          Context.current.defer(self, id, key) :
          call([id], key)[id]
      end

      # Override these methods to implement a realizer.

      # Override this method to provide a batch loader.
      # Returns a map from ids to values. By default, the realizer group is
      # coerced to an array before invoking. If you wish to preserve the
      # type of the group instance (as returned by the #new_group method), you
      # can pass `:group_as_array => false` to the constructor or override the
      # as_array method when subclassing.
      def perform(group, key)
        raise NotImplementedError
      end

      # Override this method to specify a default key by which to group the id.
      # Each unique key will result in a unique group created by #new_group
      # method. Returns a key that will be used to group ids into batches.
      def group_key(id)
        nil
      end

      # Override this method to return a container for accumulating ids.
      # Returns a new enumerable than responds to :<<.
      def new_group(key)
        Set.new
      end

      # Returns true if the realizer should coerce the enumerable group type
      # to an array before invoking the perform method.
      def group_as_array?
        !@group_as_array.nil? ? @group_as_array : true
      end

      # Initialize a new realizer instance. You can pass
      # `:group_as_array => false` as an option to disable to the default
      # coercion of realization groups to arrays.
      def initialize(options={})
        @group_as_array = options.fetch(:group_as_array, true)
      end

      # This method is overriden in subclasses to customize the sematics of the
      # return values from #perform. The default implementation is passthrough.
      def call(group, key)
        # Optionally coerce the group enumerable to an array.
        group = group.to_a if group_as_array?
        perform(group, key)
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
