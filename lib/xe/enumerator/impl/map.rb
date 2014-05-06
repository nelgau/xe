module Xe
  class Enumerator
    module Impl
      class Map < Base
        def map(&blk)
          run_map(&blk)
        end
      end
    end
  end
end
