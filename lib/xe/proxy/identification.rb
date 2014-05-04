module Xe
  class Proxy < BasicObject
    module Identification
      @mutex   ||= Mutex.new
      @last_id ||= -1

      # @protected
      # TESTING ONLY
      # Returns a unique identifier which identifies this proxy. It should only
      # be used to distinguish proxy objects for unit testing (as #object_id
      # will be delegated to the resolved subject). This value is computed
      # lazily and doesn't reflect the order in which proxies are created.
      def __proxy_id
        @__proxy_id ||= Identification.__next_id
      end

      # @protected
      # TESTING ONLY
      # Thread-safe. Returns a unique, monotonically increasing integer used to
      # identify proxy objects in units tests for chain memoization.
      def self.__next_id
        @mutex.synchronize do
          @last_id += 1
        end
      end
    end
  end
end
