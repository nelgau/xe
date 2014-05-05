module Xe
  module Realizer
    module Cacheable




      def call(group)
        ids = group.to_a
        cached_values = get_from_cache(group)

      end
    end
  end
end