module Xe
  class Target < Struct.new(:source, :id, :group_key)
    # Make this structure immutable.
    undef_method "[]=".to_sym
    members.each do |member|
      undef_method "#{member}=".to_sym
    end

    def inspect
      "<#Xe::Target [#{source}, #{id}]>"
    end

    def to_s
      inspect
    end
  end
end
