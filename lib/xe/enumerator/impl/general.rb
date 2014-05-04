module Xe
  class Enumerator
    module Impl
      class General < Base
        include Enumerable

        def each(&blk)
          enum.each(&blk)
        end

        Enumerable.instance_methods.each do |m|
          # The super keyword is incompatible with #define_method.
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{m}(*args, &blk)
              run { super(*args, &blk) }
            end
          RUBY
        end
      end
    end
  end
end
