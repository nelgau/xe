module Xe
  class Proxy < BasicObject
    module BasicObject
      # These methods are defined on the BasicObject class. Consequently, they
      # aren't delegated by #method_missing and need special handling to ensure
      # that they will be correctly invoked on the value.

      def !
        !__resolve_value
      end

      # These equality predicates are often short-circuited in Ruby's low-level
      # classes (e.g., anything derived from Struct.new). In those cases, to
      # get the expected behavior of resolution _before_ comparison, you must
      # compare the proxy to the value, not the other way around. For example:
      #
      #   struct_proxy == struct -- works fine.
      #   struct == struct_proxy -- always false.

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

      # Not overridden by convention. These methods are reserved for the real
      # identifier of an object, computed from its pointer in memory. No two
      # active objects should ever return the same value.
      # def object_id
      # def __id__

      # Not overridden by convention. In Ruby, `equals? is implemented by
      # simple pointer comparison, should be reserved for strict object-level
      # identity and never overriden by subclasses.
      # def equals?(other)

      # These are unsupported to let `rspec-mocks` work its magic.
      # def singleton_method_added(symbol)
      # def singleton_method_removed(symbol)
      # def singleton_method_undefined(symbol)
    end
  end
end
