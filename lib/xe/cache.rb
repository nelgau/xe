require 'xe/cache/base'
require 'xe/cache/store'

module Xe
  module Cache
    # Returns an cache adapter instance for a given object (i.e., it attempts
    # to wrap known cache implementations in an appropriate adapter class).
    # TODO (nelgau): Implement cache adapters for straight memcache (dalli),
    # Redis (redis-rb) and perhaps others as well.
    def self.from_impl(impl)
      case
      when impl.is_a?(Cache::Base) then impl
      when Store.is_backend?(impl) then Store.new(impl)
      else
        raise ArgumentError, "Not a valid cache implementation"
      end
    end
  end
end
