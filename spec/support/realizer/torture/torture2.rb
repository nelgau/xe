module Xe::Test
  module Realizer
    class Torture2 < Xe::Realizer::Base

      def self.for_depth(depth)
        all_depths[depth] ||= new(depth)
      end

      def self.realizers
        @realizers ||= [
          Mapper.new
        ]
      end

      attr_reader :depth

      def initialize(depth)
        @depth = depth
        @realizers = self.class.realizers
      end

      def perform(group)
        return group if depth == 0

        realizer_groups = group.group_by { |i| realizer_key[i] }

        results = Xe.enum(realizer_group).flat_map do |rk, ids|
          r = @realizers[rk]
          Xe.map(ids) { |i| [i, r[i]] }
        end

        Xe.enum(results).each_with_object({}) do |(i, v), h|
          h[i] = v
        end
      end

      def group_key(id)
        id % PRIME1
      end

      def realizer_key(id)
        id % @realizers.length
      end

      class Mapper < Xe::Realizer::Base
        def perform(ids)
          ids
        end
      end

      class Injecter < Xe::Realizer::Base

      end


    end
  end
end
