module Xe
  class Target < Struct.new(:source, :id, :group_key)
    include ImmutableStruct

    def inspect
      group_key ?
        "<#Xe::Target [#{source}, #{id.inspect} (#{group_key})]>" :
        "<#Xe::Target [#{source}, #{id.inspect}]>"
    end

    def to_s
      inspect
    end
  end
end
