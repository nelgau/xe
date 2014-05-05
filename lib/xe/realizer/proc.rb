module Xe
  module Realizer
    class Proc < Base
      attr_reader :tag
      attr_reader :realize_proc

      # Accepts a block/proc that will be invoked a group to realize its values
       #as mapping from ids to values. Optionally, you can pass a tag as the
       # first parameter (visualized by #inspect).
      def initialize(tag=nil, &realize_proc)
        raise ArgumentError, "No realizer given" unless block_given?
        @tag = tag
        @realize_proc = realize_proc
      end

      # Invokes #realize_proc to return the result map.
      def perform(group, key)
        @realize_proc.call(group, key)
      end

      def inspect
        "#<#{self.class.name}#{tag && "(#{tag})"}>"
      end

      def to_s
        inspect
      end
    end
  end
end
