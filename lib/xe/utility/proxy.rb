module Xe
  # The proxy class permits limited operations on the results of computations
  # that have yet to complete. Proxies can be stored in data structures, passed
  # to methods and, until they are introspected (e.g., by invoking a method),
  # the proxied value can remain unknown indefinitely.
  #
  # By design, the proxy contains no information about the process that
  # created it. It doesn't possesses a unique identifier. It delegates all
  # operations to the unknown value, known as the "subject." When the subject
  # is known to the proxy, the proxy is said to be "resolved."
  #
  # The resolution of a proxy can occur in two ways: 1) an external process,
  # holding a reference to the proxy, may call #__set_subject, or 2) a client
  # may invoke an arbitrary method on the proxy (or :==), forcing the
  # resolution of the proxy via the `subject_proc` passed to its initializer.
  #
  # In either case, once resolved, the proxy drops all external references
  # (except the value of the subject) by setting @subject_proc to nil. This
  # allows the enclosing scope of the Proc to be garbage collected and permits
  # proxies to outlive the context that created them.
  class Proxy < BasicObject
    # I'm unhappy with this hack. I'd prefer to have a cleaner solution for
    # distinguishing proxies from values. However, each alternative seems to
    # have non-negligable performance overhead that I'm uncomfortable
    # introducing to the case of determining that a value is _not_ a proxy.
    #
    # I considered three alternatives:
    #
    #   1) Invoke a special method defined only on proxies, rescue for values.
    #   2) Invoke #respond_to? and introduce a custom handler for proxy objects
    #      that only conditionally delegates #respond_to? to the subject.
    #   3) Add a method returning a boolean to all objects (including proxies).
    #
    # In method (1), determining the property of being a proxy (henceforth
    # 'proxiness') requires a standardized invocation-with-rescue. That's an ugly
    # pattern so naturally it needs to be stashed in a level of indirection,
    # say a metaclass method `Proxy.proxy?(object)`. In the case of a value,
    # in addition to the overhead of calling this method, we'd also invoke
    # the method_missing handler on the object, raise an exception, catch it,
    # and simply return false. This is way too heavy.
    #
    # In method (2), we appear to bump up against the method cache for values.
    # My benchmarks indicate that calling #respond_to? for non-existant methods
    # is more expensive than for existing methods, which itself is more costly
    # than a simple method call. For proxies, we'd add the additional overhead
    # of requiring special handling for the distinguishing method inside a
    # custom #respond_to? handler. This would be implemented in pure Ruby and
    # doesn't sound like a wise move from a performance perspective.
    #
    # In method (3), all determinations of proxiness use the same interface --
    # a simple method call for which the resolution will eventually enter the
    # method cache. This is the clear winner for performance. Of course, the
    # disadvantage is that all objects are polluted by that method.
    ::Object.class_eval do
      def __xe_proxy?
        # An arbitrary object is not a proxy.
        false
      end
    end

    def __xe_proxy?
      # An instance of Xe::Proxy is a proxy.
      true
    end

    attr_reader :__subject_proc
    attr_reader :__subject

    # Returns true if obj is a proxy, and false if it's a value.
    def self.proxy?(obj)
      obj.__xe_proxy?
    end

    # If obj is a proxy, this method returns the value of the resolved subject.
    # The result is always a value, even if the subject of the proxy argument
    # is itself a proxy. This mechanism is used to enforce a barrier between
    # deferred values and the targets that refer to them and to ensures that
    # resolution always occurs at well-defined moments and not in arbitrary
    # places within the implementation of the context.
    def self.resolve(obj)
      obj.__xe_proxy? ? obj.__resolve(true) : obj
    end

    def initialize(&subject_proc)
      @__subject_proc = subject_proc
      @__has_subject = false
      @__has_value = false
    end

    def ==(other)
      __resolve == other
    end

    def method_missing(method, *args, &blk)
      __resolve.__send__(method, *args, &blk)
    end

    # Proxy resolution

    # @protected
    def __resolve(to_value=false)
      return @__subject if @__has_value
      __resolve_subject if !@__has_subject
      __memoize_subject(self, to_value) if !@__has_value
      @__subject
    end

    # @protected
    def __set_subject(subject)
      @__subject = subject
      @__has_subject = true
      @__has_value = !subject.__xe_proxy?
      # Allow the garbage collector to reclaim the block's captured scope.
      @__subject_proc = nil
      subject
    end

    # @protected
    def __resolve_subject
      __set_subject(@__subject_proc.call) if !@__has_subject
    end

    # @protected
    # This method will memoize the deepest subject in the chain into the
    # receiver. If the to_value argument is true, it triggers the immediate
    # resolution of all proxies in the chain to guarantee that the receiver's
    # subject will be a value when the method returns control to the caller.
    def __memoize_subject(initiator, to_value)
      # Termination condition. The final proxy in the chain is a value.
      return @__subject if @__has_value
      # If need to return a value, each proxy in the chain must be resolved.
      @__subject.__resolve_subject if to_value
      # Termination condition. The subject has no subject.
      return @__subject if !@__subject.__subject?
      # Set the receiver's subject to the deepest resolved subject in the chain
      # and return the current subject (recursion).
      __set_subject(@__subject.__memoize_subject(initiator, to_value))
    end

    # @protected
    def __subject?
      @__has_subject
    end

    # Proxy identification for unit testing.

    # @protected
    # TESTING ONLY
    # Returns a unique identifier which identifies this proxy. It should only
    # be used to distinguish proxy objects for unit testing (as #object_id will
    # be correctly delegated to the resolved subject). This value is computed
    # lazily and doesn't reflect the order in which proxies are created.
    def __proxy_id
      @__proxy_id ||= __next_proxy_id
    end

    # @protected
    # TESTING ONLY
    # Thread-safe. Returns a unique, monotonically increasing integer used to
    # identify proxy objects in units tests for chain memoization.
    def __next_proxy_id
      @__id_mutex ||= Mutex.new
      @__id_mutex.synchronize do
        @__last_proxy_id ||= -1
        @__last_proxy_id += 1
      end
    end
  end
end
