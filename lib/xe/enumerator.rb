require 'xe/enumerator/impl'

module Xe
  class Enumerator
    # This is purely to demonstrate that the class implements the Enumerable
    # interface. In reality, every method is overridden and delegated to a
    # new instance of an implementation subclass.
    include Enumerable
    include Impl::Delegators

    attr_reader :context
    attr_reader :enumerable
    attr_reader :options

    # Initializes an instance of a defferable-aware enumerator. You can pass
    # the `:tag` option to differentiate enumerators while debugging.
    def initialize(context, enumerable, options={})
      @context = context
      @enumerable = enumerable
      @options = options
    end

    # Returns the wrapped collection. This can be useful to 'break out' of a
    # chain of deferring enumerators to use the standard methods defined in
    # the enumerable interface.
    def value
      @enumerable
    end

    # Returns the wrapped collection as an array.
    def to_a
      @enumerable.to_a
    end

    def inspect
      contents = enumerable.is_a?(Enumerator) ? "(nested)" : enumerable.inspect
      "#<#{self.class.name} #{contents}>"
    end

    def to_s
      inspect
    end
  end
end
