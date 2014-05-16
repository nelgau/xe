require 'set'

module Xe
  module Realizer
    class Base < Deferrable
      # Returns a proxy for a realized value with the given id, creating a
      # singleton instance of the realizer if none yet exists. As common
      # realizer subclasses are likely to be stateless, this is the preferred
      # shorthand for deferrals. This method delegates to #[].
      def self.[](id)
        (@default ||= new)[id]
      end

      # If an active context exists, this method returns a proxy for the
      # realized value with the given id.
      def [](id)
        # Block on the realization of the id. This enforces isolation between
        # values (which can be proxied and realized lazily) and the manner
        # by which they are referenced (ids, targets and events). This is done
        # to prevent a proxy, while being used as the id of another deferral,
        # from suspending a fiber at an arbitrary place inside the context.
        id = Proxy.resolve(id)
        key = group_key(id)
        # If an active context is available, defer the evaluation of this id.
        # Otherwise, realize the value immediately, individually and serially.
        current = Context.current
        current && current.enabled? ?
          current.defer(self, id, key) :
          call([id], key)[id]
      end

      # Override these methods to implement a realizer.

      # Override this method to provide a batch loader.
      # Returns either 1) a map from ids to values, or 2) an array of values
      # (in the same order as the group). By default, the realizer group is
      # coerced to an array before invoking. If you wish to preserve the
      # type of the group instance (as returned by the #new_group method), you
      # can override the #group_as_array method to return `false`.
      def perform(group, key)
        raise NotImplementedError
      end

      # Override this method to specify a key by which to group the given id.
      # Each unique key will create a group using #new_group. You can also
      # leave this as is to collect all keys into a single group.
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

      # Take the value returned by #perform and transform it into a hash from
      # ids to values (if it's not already in that form). If the results are
      # neither an array nor a hash, raise an error. This method can be
      # overriden to customize the behavior of subclasses.
      def transform(group, results)
        results.is_a?(Array) ?
          zip_results(group, results) :
          results
      end

      # @protected
      # Realize a group of ids as a hash from ids to values. This is the
      # designated entry point for realization via the context.
      def call(group, key)
        # Optionally coerce the group to an array.
        group = group.to_a if group_as_array?
        results = perform(group, key)
        # Apply post-processing to the result set.
        results = transform(group, results)
        # The client of this method only supports maps, raise otherwise.
        raise UnsupportedRealizationTypeError if !results.is_a?(Hash)
        results
      end

      # Memoize the hash. This value is used to compute the hash of target.
      # Profiling shows that this is a small, but significant win.
      def hash
        @hash ||= super
      end

      def inspect
        "#<#{self.class.name}>"
      end

      def to_s
        inspect
      end

      private

      # Assumes that the results were returned in the enumeration order of the
      # group argument. Zips both together and constructs a hash.
      def zip_results(group, results_array)
        pairs = group.zip(results_array)
        pairs.each_with_object({}) do |(id, value), rs|
          rs[id] = value
        end
      end
    end
  end
end
