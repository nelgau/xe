require 'xe/context/current'
require 'xe/context/scheduler'

module Xe
  class Context
    extend Current

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

    attr_reader :scheduler
    attr_reader :loom
    attr_reader :proxies
    attr_reader :cache
    attr_reader :logger

    def initialize(options={})
      @policy = options[:policy] || Policy::Default.new
      @logger = logger_from_option(options[:logger])
      @scheduler = Scheduler.new(@policy)
      @loom = Loom::Transfer.new
      @proxies = {}
      @cache = {}
    end

    def enum(e, options={})
      Enumerator.new(self, e, options)
    end

    def defer(realizer, id)
      id = Proxy.resolve(id)
      group_key = realizer.group_key_for_id(id)
      target = new_target(realizer, id, group_key)

      if cache.has_key?(target)
        log(:value_cached, target)
        return cache[target]
      end

      log(:value_deferred, target)
      scheduler.add(target)
      proxy(target) { realize_target(target) }
    end

    # This iteratively resolves all outstanding deferred values, eventually
    # releasing all fibers or detecting deadlock.
    def finalize
      log(:finalize_start)
      # Realize all outstanding deferrals
      until scheduler.empty?
        event = scheduler.next_event
        log(:finalize_step, event)
        realize_event(event)
      end
      # If fibers are still waiting but there are no deferred values in the
      # queue that might unblock them, there are no moves left in the game
      # and we have surely deadlocked.
      if loom.waiters?
        log(:finalize_deadlock)
        raise DeadlockError
      end
    end

    # @protected
    def new_target(source, id, group_key=nil)
      Target.new(source, id, group_key)
    end

    # @protected
    def dispatch(target, value)
      log(:value_dispatched, target)
      resolve(target, value)
      release(target, value)
    end

    # @protected
    def proxy(target, &blk)
      log(:proxy_new, target)
      proxy = Proxy.new { wait(target, &blk) }
      (proxies[target] ||= []) << proxy
      proxy
    end

    # @protected
    def fiber(&blk)
      log(:fiber_new)
      loom.new_fiber(&blk)
    end

    private

    def realize_target(target)
      log(:value_forced, target)
      event = scheduler.pop_event(target)
      realize_event(event)[target.id]
    end

    def realize_event(event)
      log(:event_realize, event)
      event.realize do |target, value|
        log(:value_realized, target)
        cache[target] = value
        dispatch(target, value)
      end
    end

    def wait(target, &blk)
      log(:fiber_wait, target)
      scheduler.wait(target, loom.depth)
      loom.wait(target, &blk)
    end

    def release(target, value, &blk)
      count = loom.waiter_count(target)
      log(:fiber_release, target, count)
      loom.release(target, value)
    end

    def resolve(target, value)
      target_proxies = proxies.delete(target)
      log(:proxy_resolve, target, target_proxies ? target_proxies.count : 0)
      return unless target_proxies
      target_proxies.each { |p| p.__set_subject(value) }
    end

    def logger_from_option(option)
      logger   = option == :stdout ? Logger::Text.new : option
      logger ||= Xe.default_logger
    end

    def log(*args)
      @logger.call(*args) if @logger
    end
  end
end
