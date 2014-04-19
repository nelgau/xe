require 'collude/realizer/proxy'

module Collude
  class Realizer
    def self.defer(*args)
      context = Context.current
      context ? Proxy.new(context, self, args) : realize([args])
    end

    # Takes an array of args passed to defer.
    def self.realize(many_args)
      raise NotImplementedError
    end
  end
end
