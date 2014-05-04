module Xe
  class Proxy < BasicObject
    module BasicObject
      # These methods are defined by on the BasicObject class. Consequently,
      # they won't be delegated automatically by #method_missing and need
      # special handling to ensure that they will be invoked on the value.

      def !
        !__resolve_value
      end

      def ==(other)
        __resolve_value == Proxy.resolve(other)
      end

      def !=(other)
        __resolve_value != Proxy.resolve(other)
      end

      def eql?(other)
        __resolve_value.eql?(Proxy.resolve(other))
      end

      def instance_eval(*args, &blk)
        __resolve_value.instance_eval(*args, &blk)
      end

      def instance_exec(*args, &blk)
        __resolve_value.instance_eval(*args, &blk)
      end

      # Not overridden by convention. This method is reserved for the real
      # identifier of an object, computed from its pointer in memory. No two
      # active objects should ever return the same value.
      # def object_id
      # def __id__

      # Not overridden by convention. In Ruby, `equals? is implemented by
      # simple pointer comparison, should be reserved for strict object-level
      # identity, and never overriden by subclasses.
      # def equals?(other)

      # These are unsupported to let `rspec-mocks` work its magic.
      # def singleton_method_added(symbol)
      # def singleton_method_removed(symbol)
      # def singleton_method_undefined(symbol)
    end
  end
end
