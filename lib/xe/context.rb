require 'xe/context/current'
require 'xe/context/scheduler'

module Xe
  class Context
    extend Current

    # Conditionally create a context and yield it to the block. If a context
    # already exists for this thread, the existing one is yielded instead.
    def self.wrap(options={}, &blk)
      return unless block_given?
      # If we already have a context, just yield.
      return yield(current) if current
      # Otherwise, create a new context.
      begin
        self.current = Context.new(options)
        result = yield(current)
        current.finalize!
        current.assert_vacant!
        result
      ensure
        current.invalidate!
        clear_current
      end
    end

    # Returns true if a context exists in the current thread.
    def self.exists?
      !!current
    end

    # Returns true if an enabled context exists in the current thread.
    def self.active?
      exists? && current.enabled?
    end

    attr_reader :options
    attr_reader :max_fibers
    attr_reader :policy
    attr_reader :tracer

    attr_reader :scheduler
    attr_reader :policy
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
    #   :tracer     - An instance of Xe::Tracer::Base. Defaults to nil.
    #
    def initialize(options={})
      # Merge the given options with the global config.
      @options = Xe.config.context_options.merge(options)

      @enabled    = @options.fetch(:enabled, false)
      @max_fibers = @options[:max_fibers] || 1
      @tracer     = Tracer.from_options(@options)

      @policy = @options[:policy] || Policy::Default.new
      @loom   = @options[:loom]   || Loom::Default.new

      @scheduler = Scheduler.new(policy)
      @proxies = {}
      @cache = {}
      @valid = true
    end

    # Returns a deferrable-aware enumerator for the given collection. This
    # instance conforms to the Enumerable interface.
    def enum(enumerable, options={})
      Enumerator.new(self, enumerable, options)
    end

    # Returns true when the context allows deferring values.
    def enabled?
      !!@enabled
    end

    # Returns true when the context will no longer accept new deferrals.
    def valid?
      @valid
    end

    # Finalization and Invalidation

    # Iteratively realize all outstanding deferred values, event by event,
    # It will eventually release all waiting fibers (or deadlock).
    def finalize!
      trace(:finalize_start) if @tracer
      # Realize outstanding deferrals in the order given by the scheduler.
      until scheduler.empty?
        event = scheduler.next_event
        trace(:finalize_step, event) if @tracer
        realize_event(event)
      end
      # If fibers are still waiting (but there are no deferred targets in the
      # queue that could unblock them), then the game is over and we have
      # surely deadlocked.
      if loom.waiters?
        trace(:finalize_deadlock) if @tracer
        raise DeadlockError
      end
    end

    # Raises an exception unless the context is fully resolved.
    def assert_vacant!
      raise InconsistentContextError if !scheduler.empty?
      raise InconsistentContextError if loom.running? || loom.waiters?
    end

    # After calling this method, the context will refuse to defer values.
    def invalidate!
      @valid = false
      release_all_fibers!
      invalidate_proxies!
    ensure
      # Not strictly necessary. But let's help the GC out.
      @policy = nil
      @loom = nil
      @scheduler = nil
      @proxies = nil
      @cache = nil
    end

    # Deferrals and Realization

    # Defer the realization of a single value on the deferrable by returning a
    # proxy instance. The proxy can be stored in containers and passed to
    # methods without realizing it. However, invoking a method on it will
    # suspend the execution of the current managed fiber.
    def defer(deferrable, id, group_key=nil)
      # Disallow deferrals on disabled and invalid contexts.
      raise DisabledContextError if !@enabled
      raise InvalidContextError  if !@valid
      raise DeferError if !deferrable.is_a?(Deferrable)

      target = Target.new(deferrable, id, group_key)
      # If this target was cached in a previous realization, return that value.
      if cache.has_key?(target)
        trace(:value_cached, target) if @tracer
        return cache[target]
      end

      # Defer realization of the target. Add it to the scheduler's queue of
      # deferred targets and return a proxy instance in the place of a value.
      trace(:value_deferred, target) if @tracer
      scheduler.add_target(target)
      proxy(target) do
        trace(:value_forced, target) if @tracer
        realize_target(target)
      end
    end

    # @protected
    # Immediately realizes the given target along with others that are grouped
    # with it in the scheduler's queue. If the target isn't in the scheduler,
    # this method raises InconsistentContextError.
    def realize_target(target)
      event = scheduler.pop_event(target)
      raise InconsistentContextError if !event
      realize_event(event)[target.id]
    end

    # @protected
    # Immediately realizes the given event. All realized values are dispatched
    # to their associated target, releasing any waiting fibers. The value is
    # cached in the context so that further deferrals return immediately.
    def realize_event(event)
      trace(:event_realize, event) if @tracer
      event.realize do |target, value|
        trace(:value_realized, target) if @tracer
        cache[target] = value
        dispatch(target, value)
      end
    end

    # @protected
    # Communicate a target's value to its proxies and resume any fibers that
    # are waiting on realization. Because targets don't contain unrealized
    # values, this will NEVER suspend the current fiber.
    def dispatch(target, value)
      trace(:value_dispatched, target) if @tracer
      resolve(target, value)
      release(target, value)
    end

    # Proxies

    # @protected
    # Returns a new proxy for the given target. If some invocation on the proxy
    # would require its immediate realization, the proxy will suspend the
    # execution of the current fiber and wait for the target's value to be
    # dispatched. If no managed fiber is avilable (from which to yield), the
    # proxy calls force_proc and sets the return value as its subject. If
    # this method is called on a disabled context, it will raise an exception.
    def proxy(target, &force_proc)
      # Don't allow proxies to be created on disabled contexts.
      raise DisabledContextError if !@enabled
      trace(:proxy_new, target) if @tracer
      proxy = Proxy.new { wait(target, &force_proc) }
      (proxies[target] ||= []) << proxy
      proxy
    end

    # @protected
    # Resolve any proxies for the given target by setting the value of their
    # subject. They will drop all references to the context.
    def resolve(target, value)
      target_proxies = proxies.delete(target) || []
      trace(:proxy_resolve, target, target_proxies.length)
      target_proxies.each { |p| p.__set_subject(value) }
    end

    # @protected
    # Invalidate all proxies. They will drop all references to the context.
    def invalidate_proxies!
      all_proxies = proxies.values.inject([], &:concat)
      all_proxies.each { |p| p.__invalidate! }
      proxies.clear
    end

    # Fibers

    # @protected
    # Returns a new fiber that will start execution in the given block. If
    # creating it would exceed the maximum count allowed in the context's
    # config, we will realize deferred values until a fiber becomes available.
    def begin_fiber(&blk)
      # Don't allow fibers to be created on a disabled context.
      raise DisabledContextError if !@enabled
      # If we can't start anymore fibers, free some immediately.
      free_fibers if !can_begin_fiber?
      trace(:fiber_new) if @tracer
      fiber = loom.new_fiber(&blk)
      loom.run_fiber(fiber)
      fiber
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
        trace(:fiber_free, event) if @tracer
        realize_event(event)
        # As soon as a fiber is available, we're done.
        return if can_begin_fiber?
      end
      # If we still can't create a new fiber, we've deadlocked.
      if !can_begin_fiber?
        raise DeadlockError
      end
    end

    # @protected
    # Returns true if starting a new fiber would exceed the maximum.
    def can_begin_fiber?
      !max_fibers || loom.running.length < max_fibers
    end

    # @protected
    # Suspend the execution of the current managed fiber until the value of
    # the given target becomes available. At that time, control will transfer
    # back into this method and it will return a realized value to the caller.
    # If the context is not valid after waiting, an exception is raised.
    def wait(target, &cantwait_proc)
      # Don't allow waiting on a disabled context.
      raise DisabledContextError if !@enabled
      trace(:fiber_wait, target) if @tracer
      scheduler.wait_target(target, loom.current_depth)
      result = loom.wait(target, &cantwait_proc)
      raise Xe::InvalidContextError if !@valid
      result
    end

    # @protected
    # Resume execution of fibers waiting on the target by passing the value
    # back as the result of the corresponding Context#wait invocation.
    def release(target, value)
      trace(:fiber_release, target, loom.waiter_count(target)) if @tracer
      loom.release(target, value)
    end

    # @protected
    # Release all fibers. This is called as the first step during invalidation
    # after marking the context invalid. It causes an InvalidContextError to be
    # raised in any waiting fibers. See `Context#wait`.
    def release_all_fibers!
      loom.clear
    end

    # Tracing

    # @protected
    # Log an event to the context's tracer.
    def trace(*args)
      @tracer.call(*args) if @tracer
    end

    def inspect
      if valid?
        "#<#{self.class.name}: " \
          "fibers: #{loom.running.length} " \
          "queued: #{scheduler.events.length} " \
          "proxies: #{proxies.length} " \
          "cached: #{cache.length}>"
      else
        "#<#{self.class.name}: INVALID>"
      end
    end

    def to_s
      inspect
    end
  end
end
