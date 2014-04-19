module Collude
  class Context

    def self.contexts
      Thread.current[:collude_contexts] ||= []
    end

    def self.current
      contexts.last
    end

    def self.wrap(&block)
      context = self.new
      contexts << context
      block.call(context)
    ensure
      contexts.pop
    end

    def initialize
      @proxies = []
    end

    def enumerator(enum)
      Context::Enumerator.new(self, enum)
    end




    def push_enumerator(enumerator, &block)
      @enumerators << enumerator
    end

    def start_fiber(fiber)
      @fibers << fiber
      fiber.resume(fiber)
    end

    def add_proxy(proxy)
      @proxies << proxy
    end

    def did_realize(realizer_class, args)
      realizer_class.realize([args])
    end

  end
end
