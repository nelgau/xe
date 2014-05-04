module Xe
  module Realizer
    class Id < Base
      # Use this method to pass either the name of a method or a proc that will
      # be called on each realized value to determine its identifier.
      def self.id(id_m=nil, &id_blk)
        new_proc = id_m ? ::Proc.new { |v| v.send(id_m) } : id_blk
        @id = new_proc || @id
      end

      # The default id derivation proc that simply calls #id on the value.
      def self.default_id_proc
        @@default_id_proc ||= ::Proc.new { |v| v.id }
      end

      attr_reader :id_proc

      # Accepts a proc that transforms realized values back into their
      # associated ids. If no block is given, it falls back to the class-level
      # 'id' attribute. Finally, if that hasn't been defined, the default proc
      # that derives the id from the #id method will be used.
      def initialize(options={}, &id_proc)
        super(options)
        @id_proc = id_proc || self.class.id || self.class.default_id_proc
      end

      # Override this method to provide a batch loader.
      # Returns an enumerable of loaded values. These values are required to
      # identify using the proc passed to the initializer. The group argument
      # may be of the type returned by the #new_group method, or it may be an
      # arbitrary object instance that conforms to the enumerable interface.
      def perform(group)
        raise NotImplementedError
      end

      # Calls perform and returns a hash from derived identifiers (as keys) to
      # realized values. Derivation uses the #id_proc attribute.
      def call(group)
        super.each_with_object({}) do |v, rs|
          rs[@id_proc.call(v)] = v
        end
      end
    end
  end
end
