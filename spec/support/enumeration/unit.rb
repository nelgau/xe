module Xe::Test
  module Enumeration
    # This class represents a single enumeration operation to be preformed by
    # one of the runner classes. The items attribute may be either 1) another
    # instnace of unit or 1) a arbitrary object conforming to Enumerable.
    # In the case of (1), the enumeration will be "chained" -- the output of
    # the parent unit enumeration will be used to invoke the second enumeration.
    # For the general case of (2), each value in the enum attribute will be
    # expanded if it is an instance of Unit; otherwise, it is a pass-through.
    class Unit
      include Enumerable

      attr_reader :realizer
      attr_reader :items

      def initialize(realizer, items=[])
        @realizer = realizer
        @items = items
      end

      def each(&blk)
        @items.each(&blk)
      end
    end
  end
end
