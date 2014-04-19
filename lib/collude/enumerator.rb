require 'collude/enumerator/provider'
require 'collude/enumerator/fiber'

module Collude
  class Enumerator
    include Enumerable

    def initialize(context, enumerable)
      @context = context
      @enumerable = enumerable
    end

    (Enumerable.instance_methods + [:each]).each do |m|
      define_method(m) do |*args, &block|
        Implementation.new(context, enumerable).send(m, *args, &block)
      end
    end
  end
end
