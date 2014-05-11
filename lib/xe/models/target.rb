module Xe
  class Target < Struct.new(:source, :id, :group_key)
    include ImmutableStruct

    def inspect
      "<#Xe::Target [#{source}, #{id}]>"
    end

    def to_s
      inspect
    end
  end
end
