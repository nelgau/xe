module Xe
  class Enumerator
    module Implementation
      # Big Three

      # Invokes the block once for each element in the enumerable. Returns a
      # new array of all the elements.
      def each(&blk)
        run_mapper { |o| blk.call(o); o }
      end

      # Returns a new array from the results of running the block once for each
      # element in the enumerable. Substitutes proxies for unrealized values.
      def map(&blk)
        run_mapper(&blk)
      end

      # Returns the result of folding a block over the enumerable starting with
      # the given initial value.
      def inject(initial, &blk)
        run_injector(initial, &blk)
      end

      # Injection

      def each_with_object(obj, &blk)
        run_injector(obj) { |acc, o| blk.call(o, acc); acc }
      end
    end
  end
end
