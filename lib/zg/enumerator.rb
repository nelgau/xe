require 'zg/enumerator/provider'
require 'zg/enumerator/fiber'

module Zg
  class Enumerator
    include Enumerable

    attr_reader :context
    attr_reader :enum

    def initialize(context, enum)
      @context = context
      @enum = enum
    end

    # All enumerable methods return a proxy object.
    (Enumerable.instance_methods + [:each]).each do |m|
      define_method(m) do |*arg, &b|
        provider = Provider.class_for_method(method).new(context, enum)
        provider.send(m, *args, &block)
        Proxy.new do |c|
          c.
        end
      end
    end
  end
end
