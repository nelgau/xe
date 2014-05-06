module Xe
  class Enumerator
    module Impl
      class Each < Base
        def each(&blk)
          run_map { blk.call(obj); obj }
        end
      end
    end
  end
end
