module Xe
  module Cache
    # The super class from which all cache adapters descend. This abstract
    # class is intended to define an interface. You should overriden only those
    # methods that can be efficiently supported by your cache backend.
    class Base
      # Methods for cache access. Subclasses should override at least the
      # get and set methods to implement the cache interface.

      # Override with an implementation that retrieves and returns the cached
      # value for the given key, or nil if absent.
      def get(key)
        nil
      end

      # Override with an implementation that sets the cached value for the
      # given key. Pass the :expires_in option to specify an expiration time
      # for keys (seconds). Others options should forwarded to the backend.
      def set(key, value, options={})
        return
      end

      # Override with an implementation that retrieves the cache values for
      # many keys (or nil if the key is absent) and returns the results as a
      # hash from keys to values.
      def get_multi(keys)
        keys.each_with_object({}) do |key, results|
          results[key] = get(key)
        end
      end

      # Override with an implementation that sets the cached value for many
      # keys using the given key_value_map hash. Pass the :expires_in option to
      # specify an expiration time (seconds). Others options should forwarded
      # to the backend.
      def set_multi(key_value_map, options={})
        key_value_map.each do |key, value|
          set(key, value)
        end
      end
    end
  end
end
