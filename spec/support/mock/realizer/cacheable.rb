module Xe::Test
  module Mock
    module Realizer
      module Cacheable
        # Returns a cache object with an in-memory store.
        def new_cache_mock(cached_values)
          Cache.new(cached_values)
        end

        class Cache < Xe::Cache::Base
          attr_reader :cached_values

          def initialize(cached_values)
            @cached_values = cached_values.dup
          end

          def get(key)
            @cached_values[key]
          end

          def set(key, value)
            @cached_values[key] = value
          end
        end
      end
    end
  end
end
