require 'set'

module Xe
  module Realizer
    class Base < Deferrable
      # On passing group keys to .[] and #[] ...
      #
      # Smart clients of Realizer::Base may know best how to group
      # realizations. Since delegating this responsibility into the realizer
      # subclass itself (using #group_key) may not be the most effective
      # factoring (to keep the type of group members trivial, like integers,
      # and push all information about 'how' to realize values into the key
      # type), this interface is provided for the advanced consumer.

      # Returns a proxy for a realized value with the given id, creating a
      # singleton instance of the realizer if none yet exists. As common
      # realizer subclasses are likely to be stateless, this is the preferred
      # shorthand for deferrals. This method delegates to #[].
      def self.[](id, key=nil)
        (@default ||= new)[id, key]
      end

      # If an active context exists, this method returns a proxy for the
      # realized value with the given id. If no key is given, the #group_key
      # method is invoked to provide one.
      def [](id, key=nil)
        # Block on the realization of the id. This enforces isolation between
        # values (which can be proxied and realized lazily) and the manner
        # by which they are referenced (ids, targets and events). This is done
        # to prevent a proxy, while being used as the id of another deferral,
        # from suspending a fiber at an arbitrary place inside the context.
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
      # can override the #group_as_array method to return `false`. If your
      # realizer subclass doesn't group ids by key, you may define #perform
      # to take a single argument (the group enumerable).
      def perform(group, key)
        raise NotImplementedError
      end

      # Override this method to specify the default key by which to group the
      # given id. Each unique key will create a group using #new_group.
      def group_key(id)
        nil
      end

      # Override this method to return a container for accumulating ids.
      # Returns a new enumerable that responds to :<<.
      def new_group(key)
        Set.new
      end

      # Returns true if the realizer should coerce the group type to an array
      # before invoking the #perform method.
      def group_as_array?
        true
      end

      # This method is overriden in subclasses to customize the sematics of
      # the #perform method. The default implementation is pass-through.
      def call(group, key=nil)
        # Optionally coerce the group to an array.
        group = group.to_a if group_as_array?
        # Support overridden #perform implementations with both signatures.
        # Not all realizers require grouping and for some use cases, the
        # argument might be confusing.
        @perform_arity ||= method(:perform).arity
        (@perform_arity == 2) ? perform(group, key) : perform(group)
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
