require 'xe/enumerator/impl'

module Xe
  class Enumerator
    # This is purely to demonstrate that the class implements the Enumerable
    # interface. In reality, every method is overridden and delegated to a
    # new instance of an implementation subclass.
    include Enumerable

    attr_reader :context
    attr_reader :enum
    attr_reader :options

    # Initializes an instance of a defferable-aware enumerator. You can pass
    # the `:tag` option to differentiate enumerators while debugging.
    def initialize(context, enum, options={})
      @context = context
      @enum = enum
      @options = options
    end

    (Enumerable.instance_methods + [:each]).each do |m|
      define_method(m) do |*args, &blk|
        Impl.new(m, context, enum, options).send(m, *args, &blk)
      end
    end
  end
end
