module Xe
  class Enumerator
    module Impl
      class Mappable < Base
        # Returns a new array with the results of running block once for every
        # element in enum. Substitutes proxies for deferred values.
        def map(&blk)
          run_map(&blk)
        end

        # Like #map, except that it returns the original collection.
        def each(&blk)
          run_map { |o| blk.call(o); o }
        end
      end
    end
  end
end
