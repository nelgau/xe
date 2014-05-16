module Xe
  module Cache
    # Cache adapter for ActiveSupport::Cache::Store-like classes. Some
    # implementations, notably DalliStore, don't actually descend from the
    # Store superclass. In that case, to determine if this adapter is
    # applicable, we fall-back to a simple ducktyping test.
    class Store
      attr_reader :backend

      # List of methods that a store-like class must implement.
      BACKEND_METHODS = [
        :fetch,
        :read,
        :write,
        :fetch_multi,
        :read_multi
      ]

      # Returns true if the backend is compatible.
      def self.is_backend?(obj)
        BACKEND_METHODS.all? { |m| obj.respond_to?(m) }
      end

      def initialize(backend, options={})
        raise "Not a store" if !self.class.is_backend?(backend)
        super(options)
        @backend = backend
      end

      # Retrieves and returns the cached value for a key, or nil if absent.
      def get(key)
        @backend.read(key)
      end

      # Sets the cached value for the given key. Pass the :expires_in option to
      # specify an expiration time (seconds).
      def set(key, value)
        @backend.write(key, value, options)
      end

      # Retrieves the cache values for many keys (or nil if the key is absent)
      # and returns the results as a hash from keys to values.
      def get_multi(keys)
        @backend.read_multi(*keys)
      end
    end
  end
end
