module Xe
  module Realizer
    # This module can be included in a realizer subclass to add caching
    # behavior. Deferred values (from #[]) will yield a reference to the cache,
    # any values that aren't cache will defer to the original realizer. You
    # should use the use_cache class method to set the cache adapter and
    # options. For example:
    #
    #     class WidgetCountRealizer < Xe::Realizer::Base
    #       include Xe::Realizer::Cacheable
    #
    #       using_cache Rails.cache,
    #         :prefix => 'cache:widget_counts:',
    #         :expires_in => 60
    #
    #       def perform(ids)
    #         Widgets.get_counts(:id => ids)
    #       end
    #     end
    #
    module Cacheable
      # Invoked when the module is included in a realizer.
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        attr_reader :cache
        attr_reader :cache_prefix
        attr_reader :cache_options

        # Sets the cache adapter implementation and caching options. You may
        # also pass a backend for any of the internal cache adapter classes.
        # Pass the :prefix option to pre-append a string to all cache keys or
        # the :expires_in option to specify an expiration time for keys
        # (seconds). Other options are passed to the cache adapter's backend.
        def use_cache(cache, options={})
          options = options.dup
          @cache_prefix  = options.delete(:prefix)
          @cache_options = options
          @cache = Cache.from_impl(cache)
        end
      end

      attr_accessor :cache
      attr_accessor :cache_prefix
      attr_accessor :cache_options

      # If an active context exists, this method returns a proxy for the
      # cached value with the given id. You can pass the :uncached => true
      # option to ignore the cache and access the realizer's values directly.
      def [](id, options={})
        use_cache = !cache.nil? && !options.fetch(:uncached, false)
        use_cache ? cache_realizer[id] : super(id)
      end

      # Override this method to return true is the given realized value should
      # be cached, or false otherwise.
      def cache?(id, value)
        true
      end

      # Override this method to specify a cache key for the given id.
      def cache_key(id)
        id.to_s
      end

      # @protected
      # Realize a group of ids as a hash from ids to values. Stores any
      # cacheable values in the realizer's cache.
      def call(group, key)
        results = super
        # Filter the result set to the values that are cacheable.
        cacheable = results.select { |id, val| cache?(id, val) }
        set_cached(cacheable)
        results
      end

      # @protected
      # Returns the memoized cache realizer instance.
      def cache_realizer
        # Returns a hash mapping group ids to either cached values or
        # deferrals of the original realizer's values.
        @cache_realizer ||= Realizer::Proc.new(cache_tag) do |group|
          results = get_cached(group)
          group.each { |id| results[id] ||= self[id, uncached: true] }
          results
        end
      end

      # @protected
      # Returns the memoized class-level caching attributes.
      def cache;         @cache         ||= self.class.cache;         end
      def cache_prefix;  @cache_prefix  ||= self.class.cache_prefix;  end
      def cache_options; @cache_options ||= self.class.cache_options; end

      # @protected
      # Returns a tag name for the cache realizer instance (debugging).
      def cache_tag
        "#{self.class.name}/cache"
      end

      private

      # @protected
      # Retrieves an array of ids from the cache as a hash from ids to values.
      def get_cached(group)
        # If no cache is defined, there are no cached values.
        return {} if !cache
        # Retrieve the cached values by their full prefixed key.
        key_map = key_map_for_ids(group)
        from_cache = cache.get_multi(key_map.keys)
        from_cache.each_with_object({}) do |(key, value), results|
          # Don't return nil values.
          results[key_map[key]] = value
        end
      end

      # @protected
      # Store the given hash of ids to values into the cache.
      def set_cached(results)
        # If no cache is defined, nothing to do.
        return if !cache
        # Store the values in cache by their full prefixed key.
        key_map = key_map_for_ids(results.keys)
        to_cache = key_map.each_with_object({}) do |(key, id), hash|
          value = results[id]
          # Don't store nil values.
          hash[key] = value if value
        end
        cache.set_multi(to_cache, cache_options)
      end

      # Constructs a map from full prefixed keys to ids.
      def key_map_for_ids(group)
        group.each_with_object({}) do |id, km|
          prefixed_key = "#{cache_prefix}#{cache_key(id)}"
          km[prefixed_key] = id
        end
      end
    end
  end
end
