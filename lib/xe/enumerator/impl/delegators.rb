module Xe
  class Enumerator
    module Impl
      module Delegators
        # Include `each` because it's a dependency of Enumerable, not part of
        # the interface itself.
        DELEGATED_METHODS = Enumerable.instance_methods + [:each]

        # For each delegate, define a new method that instantiates a fresh
        # enumeration implementation and invokes the operation.
        DELEGATED_METHODS.each do |m|
          define_method(m) do |*args, &blk|
            begin
              impl = Impl.new(m, enumerable, options)
              impl.send(m, *args, &blk)
            ensure
              # Drop references to external objects.
              impl.invalidate! if impl
            end
          end
        end
      end
    end
  end
end
