require 'xe/context/fiber'
require 'xe/context/scheduler'
require 'xe/context/queue'
require 'xe/context/cache'
require 'thread'

module Xe
  class Context
    def self.current
      Thread.current[:xe]
    end

    def self.wrap
      # If we already have a context, yield it.
      return yield current if current
      # Otherwise, create a new context.
      begin
        Thread.current[:xe] = new
        yield current
      ensure
        current.finalize
        Thread.current[:xe] = nil
      end
    end

    attr_reader :scheduler
    attr_reader :queue
    attr_reader :cache

    def initialize
      @scheduler = Scheduler.new
      @cache = Cache.new

      @queue = Queue.new do |realizer, id, value|
        dispatch(realizer, id, value)
      end
    end

    def enum(enumerable)
      Enumerator.new(self, enumerable)
    end

    def defer(realizer, id)
      is_cached, cached_value = cache.get(realizer, id)
      return cached_value if is_cached

      queue.add(realizer, id)
      proxy do
        queue.realize(realizer, id)
      end
    end

    # This iteratively resolves all outstanding deferral, releasing all fibers,
    # and detects deadlock.
    def finalize
      # Realize all outstanding deferrals
      queue.flush until queue.empty?
      # If fibers are still waiting but there are no deferrals in the queue
      # that might unblock them, the there are no moves left in the game and
      # we have deadlocked.
      raise DeadlockError if scheduler.waiters?
    end

    # @private
    def proxy(source, id, &blk)
      Proxy.new(self) do
        scheduler.wait([source, id], &blk)
      end
    end

    # @private
    def fiber(&blk)
      scheduler.fiber(&blk)
    end

    private

    def dispatch(realizer, id, value)
      cache.set(realizer, id, value)
      scheduler.dispatch([realizer, id], value)
    end
  end
end
