module Xe
  class Enumerator
    module Impl
      # This class implements the remaining methods by including Enumerable
      # and defining a trivial #each method. All operations are wrapped in
      # a #run_value block and therefore use a single fiber.
      class General < Base
        include Enumerable
        extend Forwardable

        Enumerable.instance_methods.each do |m|
          # The super keyword is incompatible with #define_method.
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{m}(*args, &blk)
              run_value(&self.class.build(:#{m}, enumerable, *args, &blk))
            end
          RUBY
        end

        def self.build(m, e, *args, &blk)
          Proc.new { e.send(m, *args, &blk) }
        end
      end
    end
  end
end
