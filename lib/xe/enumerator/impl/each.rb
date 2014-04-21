module Xe
  class Enumerator
    module Impl

      class Each
        def each(&blk)
          map_with_index do |obj, index|
            run(index) { blk.call(obj); obj }
          end
        end
      end

    end
  end
end
