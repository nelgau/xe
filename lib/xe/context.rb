require 'xe/context/current'
require 'xe/context/manager'
require 'xe/context/queue'
require 'xe/context/private'

module Xe
  class Context
    extend Current
    include Private

    def self.wrap(options={}, &blk)
      # If we already have a context, yield it.
      return yield current if current
      # Otherwise, create a new context.
      begin
        self.current = self.new(options)
        result = blk.call(current)
        current.finalize
        result
      ensure
        clear_current
      end
    end

    def enum(enumerable)
      Enumerator.new(self, enumerable)
    end

    def defer(realizer, id)
      key = [realizer, id]
      if cache.has_key?(key)
        log(:value_cached, realizer, id)
        return cache[key]
      end

      log(:value_deferred, realizer, id)
      queue.add(realizer, id)
      proxy(realizer, id) do
        log(:value_realized, realizer, id)
        queue.realize(realizer, id)
      end
    end

    # This iteratively resolves all outstanding deferred values, eventually
    # releasing all fibers or detecting deadlock.
    def finalize
      log(:finalize_start)
      # Realize all outstanding deferrals
      until queue.empty?
        log(:finalize_step, queue.group_count, queue.item_count)
        queue.flush
      end
      # If fibers are still waiting but there are no deferred values in the
      # queue that might unblock them, there are no moves left in the game
      # and we have surely deadlocked.
      if manager.waiters?
        log(:finalize_deadlock)
        raise DeadlockError
      end
    end
  end
end
