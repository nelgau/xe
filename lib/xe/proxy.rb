require 'xe/proxy/basic_object'
require 'xe/proxy/identification'
require 'xe/proxy/debugging'

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
  # may invoke an arbitrary method on the proxy (or say, :==), forcing the
  # resolution of the proxy via the `subject_proc` passed to its initializer.
  #
  # In either case, once resolved, the proxy drops all external references
  # (except the value of the subject) by setting @subject_proc to nil. This
  # allows the enclosing scope of the Proc to be garbage collected and permits
  # proxies to outlive the context that created them.
  #
  # When the resolved subject of a proxy is itself another proxy, this class
  # attempts to recursively memoize subject of the deepest proxy in the chain
  # as its own, optionally forcing the resolution of all intermediate proxies.
  class Proxy < BasicObject
    include Proxy::BasicObject
    include Proxy::Identification

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

    # Enables instance method tracing for the proxy.
    def self.debug!
      send(:include, Debugging)
    end

    attr_reader :__resolve_proc
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
      obj.__xe_proxy? ? obj.__resolve_value : obj
    end

    # Accepts a proc that will be called when the proxy is forced to resolve.
    # The return value will become the immediate subject of the proxy (at least
    # until an attempt is made to memoize the subject's chain).
    def initialize(&resolve_proc)
      ::Kernel.raise ::ArgumentError, "No resolve block given" if !resolve_proc
      @__resolve_proc = resolve_proc
      @__subject = nil
      @__has_subject = false
      @__has_value = false
    end

    # After resolution, Delegate a method invocation to the proxy's value.
    def method_missing(method, *args, &blk)
      __resolve_value.__send__(method, *args, &blk)
    end

    # Resolution

    # Resolves and returns the subject. If the subject is itself a proxy, this
    # method walks the chain of resolved proxies and returns the deepest
    # subject (by default, without forcing resolution). If the second argument
    # (to_value) is true, it will resolve as necessary to ensure that the
    # returned result is a value.
    def __resolve(to_value=false)
      return @__subject if @__has_value
      __resolve_subject if !@__has_subject
      __memoize_subject(self, to_value)
    end

    # Recursely resolve the proxy until the subject is value. This method
    # always returns a value.
    def __resolve_value
      @__has_value ? @__subject : __resolve(true)
    end

    # Returns true if the proxy is resolved and has a subject.
    def __resolved?
      @__has_subject
    end

    # Returns true if the proxy is resolved and the subject is a value.
    def __value?
      @__has_value
    end

    # @protected
    # Set the proxy's subject and drops all references to the enclosing scope
    # of the resolution procedure. This method is called by the context when a
    # realization event occurs. It is not a public interface.
    def __set_subject(subject)
      @__subject = subject
      @__has_subject = true
      @__has_value = !subject.__xe_proxy?
      # Allow the garbage collector to reclaim the block's captured scope.
      @__resolve_proc = nil
      @__subject
    end

    # The following methods are used for deep subject resolution and
    # memoization. They are a private interface between proxies.

    # @protected
    # If the receiver doesn't have a subject, set it using the realization
    # procedure passed to the initializer. Returns the receiver's subject.
    def __resolve_subject
      __set_subject(@__resolve_proc.call) if !@__has_subject
      @__subject
    end

    # @protected
    # Memoize the deepest subject in the chain into the receiver. If the
    # to_value argument is true, it triggers the immediate resolution of all
    # proxies in the chain to guarantee that the receiver's subject will be a
    # value when the method returns control to the caller.
    def __memoize_subject(initiator, to_value)
      # Termination condition. The final proxy in the chain is a value.
      return @__subject if @__has_value
      # If need to return a value, each proxy in the chain must be resolved.
      @__subject.__resolve_subject if to_value
      # Termination condition. The subject has no subject.
      return @__subject if !@__subject.__resolved?
      # Set the receiver's subject to the deepest resolved subject in the chain
      # and return the current subject (recursion).
      __set_subject(@__subject.__memoize_subject(initiator, to_value))
    end
  end
end
