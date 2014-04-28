require 'xe/enumerator/impl'

module Xe
  class Enumerator
    # This is purely to demonstrate that the class implements the Enumerable
    # interface. In reality, every method is overriden.
    include Enumerable

    attr_reader :context
    attr_reader :enum
    attr_reader :options

    def initialize(context, enum, options={})
      @context = context
      @enum = enum
      @options = options
    end

    # All enumerable methods return a proxy object or array of proxies.
    (Enumerable.instance_methods + [:each]).each do |m|
      define_method(m) do |*args, &blk|
        Impl.new(m, context, enum, options).send(m, *args, &blk)
      end
    end
  end
end
