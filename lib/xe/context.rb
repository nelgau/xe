require 'xe/context/current'
require 'xe/context/scheduler'
require 'xe/context/waiter'

module Xe
  class Context
    extend Current

    # Returns true if a context exists in the current thread.
    def self.exists?
      !!current
    end

    # Returns true if an enabled context exists in the current thread.
    def self.active?
      exists? && current.enabled?
    end

    attr_reader :max_fibers
    attr_reader :policy
    attr_reader :logger

    attr_reader :scheduler
    attr_reader :loom
    attr_reader :proxies
    attr_reader :cache

    # Initializes a new context. This method consumes a hash of options that
    # can be used to control the behavior of deferred evaluation.
    #
    #   :enabled    - If false, the context realizes all deferrals immediately
    #                 and doesn't create any fibers.
    #   :max_fibers - Maximum number of fibers to run concurrently. Creating
    #                 a fiber that would exceed this threshold causes
    #                 immediate realization of deferred values.
    #   :logger     - An instance of Xe::Logger::Base. Defaults to nil.
    #
    def initialize(options={})
      # Merge the given options with the global config.
      options = Xe.config.context_options.merge(options)

      @enabled    = options.fetch(:enabled, false)
      @max_fibers = options[:max_fibers] || 1
      @logger     = Logger.from_options(options)

      @policy = options[:policy] || Policy::Base.new
      @loom   = options[:loom]   || Loom::Default.new

      @scheduler = Scheduler.new(policy)
      @proxies = {}
      @cache = {}
      @valid = true
    end

    # Returns a deferrable-aware enumerator for the given collection. This
    # instance conforms to the Enumerable interface.
    def enum(enumerable, options={})
      Enumerator.new(enumerable, options)
    end

    # Iteratively realize all outstanding deferred values, event by event,
    # It will eventually release all waiting fibers (or deadlock).
    def finalize
      log(:finalize_start)
      # Realize outstanding deferrals in the order given by the scheduler.
      until scheduler.empty?
        event = scheduler.next_event
        log(:finalize_step, event)
        realize_event(event)
      end
      # If fibers are still waiting (but there are no deferred targets in the
      # queue that could unblock them), then the game is over and we have
      # surely deadlocked.
      if loom.waiters?
        log(:finalize_deadlock)
        raise DeadlockError
      end
    end

    # Returns true when the context allows deferring values.
    def enabled?
      !!@enabled
    end

    # Returns true when the context will no longer accept new deferrals.
    def valid?
      @valid
    end

    # After calling this method, the context will refuse to defer values.
    def invalidate!
      @valid = false
    end

    # @protected
    # Defer the realization of a single value on the deferrable by returning a
    # proxy instance. The proxy can be stored in containers and passed to
    # methods without realizing it. However, invoking a method on it will
    # suspend the execution of the current managed fiber.
    def defer(deferrable, id, group_key=nil)
      # Explicitly disallow deferred realization on disabled contexts. This
      # case should be handled internally by the realizer base class.
      raise DeferError, "Context is disabled"  if !enabled?
      raise DeferError, "Context is invalid"   if !valid?
      raise DeferError, "Value not deferrable" if !deferrable.is_a?(Deferrable)

      target = Target.new(deferrable, id, group_key)
      # If this target was cached in a previous realization, return that value.
      if cache.has_key?(target)
        log(:value_cached, target)
        return cache[target]
      end

      # Defer realization of the target. Add it to the scheduler's queue of
      # deferred targets and return a proxy instance in the place of a value.
      log(:value_deferred, target)
      scheduler.add_target(target)

      waiter_proc = Waiter.build_realize(self, target)
      proxy(target, waiter_proc)
    end

    # @protected
    # Communicate a target's value to its proxies and resume any fibers that
    # are waiting on realization. Because targets don't contain unrealized
    # values, this will NEVER suspend the current fiber.
    def dispatch(target, value)
      log(:value_dispatched, target)
      resolve(target, value)
      release(target, value)
    end

    # @protected
    # Returns a new proxy for the given target. If some invocation on the proxy
    # would require its immediate realization, the proxy will suspend the
    # execution of the current fiber and wait for the target's value to be
    # dispatched. If no managed fiber is avilable (from which to transfer
    # control), the proxy will call the block that was passed to this method.
    def proxy(target, waiter_proc)
      log(:proxy_new, target)
      proxy = Proxy.new(waiter_proc)
      (proxies[target] ||= []) << proxy
      proxy
    end

    def new_fiber(blk)
      # free_fibers unless can_run_fiber?
      log(:fiber_new)
      loom.new_fiber(blk)
    end

    # @protected
    # Realize outstanding events in the scheduler's queue until the count of
    # running fibers drops below the maximum. This is called when the context
    # attempts to create a fiber that would exceed the configured threshold.
    def free_fibers
      # Realize outstanding deferrals until we can create a fiber or we
      # exhaust all events in the scheduler.
      until scheduler.empty?
        event = scheduler.next_event
        log(:fiber_free, event)
        realize_event(event)
        # As soon as a fiber is available, we're done.
        return if can_run_fiber?
      end
      # If we still can't create a new fiber, we've deadlocked.
      if !can_run_fiber?
        raise DeadlockError
      end
    end

    # @protected
    # Returns true if starting a new fiber would exceed the maximum.
    def can_run_fiber?
      !max_fibers || loom.running.count < max_fibers
    end

    # @protected
    # Immediately realizes the given target along with others that are grouped
    # with it in the scheduler's queue.
    def realize_target(target)
      log(:value_forced, target)
      event = scheduler.pop_event(target)
      realize_event(event)[target.id]
    end

    # @protected
    # Immediately realizes the given event. All realized values are dispatched
    # to their associated target, releasing any waiting fibers. The value is
    # cached in the context so that further deferrals return immediately.
    def realize_event(event)
      log(:event_realize, event)
      event.realize do |target, value|
        log(:value_realized, target)
        # cache[target] = value
        dispatch(target, value)
      end
    end

    # @protected
    # Suspend the execution of the current managed fiber until the value of
    # the given target becomes available. At that time, control will transfer
    # back into this method and it will return a realized value to the caller.
    def wait(target)
      log(:fiber_wait, target)
      scheduler.wait_target(target, loom.current_depth)
      loom.wait(target) { yield }
    end

    # @protected
    # Resume execution of fibers waiting on the target by passing the value
    # back as the result of the corresponding Context#wait invocation.
    def release(target, value)
      count = loom.waiter_count(target)
      log(:fiber_release, target, count)
      loom.release(target, value)
    end

    # @protected
    # Explicitly resolve any proxies for the given target. They will drop all
    # references to the context before #__set_subject returns.
    def resolve(target, value)
      target_proxies = proxies.delete(target)
      log(:proxy_resolve, target, target_proxies ? target_proxies.count : 0)
      Context.set_subjects(target_proxies, value) if target_proxies
    end

    def self.set_subjects(proxies, value)
      proxies.each { |p| p.__set_subject(value) }
    end

    # @protected
    # Log an event to the context's logger.
    def log(*args)
      @logger.call(*args) if @logger
    end

    def inspect
      "#<#{self.class.name}: " \
        "fibers: #{loom.running.length} " \
        "queued: #{scheduler.events.length} " \
        "proxies: #{proxies.length} " \
        "cached: #{cache.length}>"
    end

    def to_s
      inspect
    end
  end
end
