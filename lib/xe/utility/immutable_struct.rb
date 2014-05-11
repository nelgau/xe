module Xe
  # When included into a Struct, it makes the instances immutable. This has
  # less to do with type-safety and correctness, and is really a performance
  # optimization for the #hash method.
  module ImmutableStruct
    def self.included(base)
      base.class_exec do
        # Remove all accessors from the implementation.
        undef_method "[]=".to_sym
        members.each do |member|
          undef_method "#{member}=".to_sym
        end
      end
    end
    # As the structure is immutable, the hash cannot change.
    def hash
      @hash ||= super
    end
  end
end
