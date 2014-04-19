require 'thread'
require 'set'

module Zg
  class Context
    def self.current
      Thread.current[:zg]
    end

    def self.current=(context)
      Thread.current[:zg] = context
    end

    def self.wrap
      new_ctx = new if !current
      self.current ||= new_ctx
      yield self.current
      current.finalize if new_ctx
    ensure
      self.current = nil if new_ctx
    end

    def self.defer(source, id)
      current ?
        current.defer(source, id) :
        source.call([id])
    end

    attr_reader :scheduler
    attr_reader :pending_sources

    def initialize
      @scheduler = Scheduler.new
      @pending_sources = Set.new
    end

    def finalize

    end

    def defer(source, id)
      pending_sources.add(source)
      Proxy.new(self) { wait(source, id) }
    end

    def enumerator(enum)
      Context::Enumerator.new(self, enum)
    end

    def wait(source, id=nil)
      scheduler.wait(source, id)
    end

    def dispatch(source, id, value)
      scheduler.dispatch(source, id, value)
    end
  end
end
