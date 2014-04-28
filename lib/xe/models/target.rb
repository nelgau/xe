module Xe
  class Context
    class Target < Struct.new(:source, :id, :group_key)
      def inspect
        "<#Xe::Target [#{source}, #{id}]>"
      end

      def to_s
        inspect
      end
    end
  end
end
