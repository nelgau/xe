module Xe
  class Enumerator
    module Impl
      class Map < Base
        def map(&blk)
          map_with_index do |obj, index|
            run(index) { blk.call(obj) }
          end
        end
      end
    end
  end
end
