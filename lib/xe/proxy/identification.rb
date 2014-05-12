module Xe
  class Proxy < BasicObject
    module Identification
      @last_id ||= -1

      # @protected
      # TESTING AND DEBUGGING ONLY
      # Returns a unique identifier for this proxy. This value is assigned
      # lazily and doesn't reflect an order on proxy creation.
      def __proxy_id
        @__proxy_id ||= Identification.__next_id
      end

      # @protected
      # TESTING AND DEBUGGING ONLY
      # Returns a unique, monotonically increasing integer used to
      # identify proxy objects for debugging chain memoization.
      def self.__next_id
        @last_id += 1
      end
    end
  end
end
