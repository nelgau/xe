module Xe::Test
  module Mock
    module Enumerator
      # Returns a new minimal context implementation.
      def new_context_mock(options={}, &finalize_proc)
        Context.new(options, &finalize_proc)
      end

      # Returns a new minimal proxy implementation.
      def new_proxy_mock(&resolve_proc)
        Proxy.new(&resolve_proc)
      end

      # Returns true if the object is an instance of the minimal proxy.
      def is_proxy?(object)
        object.is_a?(Proxy)
      end

      # This is a minimal implementation of the Xe::Context class to support
      # testing of enumeration strategies without invoking the full
      # complexity of the gem (like scheduling, policies and the loom).
      class Context
        attr_reader :finalize_proc
        attr_reader :root_fiber
        attr_reader :last_fiber
        attr_reader :proxies
        attr_reader :waiters

        def initialize(options={}, &finalize_proc)
          @enabled = options.fetch(:enabled, true)
          @tracing = options.fetch(:tracing, false)
          @finalize_proc = finalize_proc || Proc.new {}
          @root_fiber = ::Fiber.current
          @proxies = {}
          @waiters = {}
        end

        def enabled?
          !!@enabled
        end

        def tracing?
          !!@tracing
        end

        def finalize!
          trace(:finalize_start)
          @finalize_proc.call
        end

        def dispatch(target, value)
          trace(:value_dispatched, target, value)
          resolve(target, value)
          release(target, value)
        end

        def proxy(target, &force_proc)
          trace(:proxy_new, target)
          proxy = Proxy.new { wait(target, &force_proc) }
          (proxies[target] ||= []) << proxy
          proxy
        end

        def resolve(target, value)
          target_proxies = proxies.delete(target) || []
          trace(:proxy_resolve, target, target_proxies.length)
          target_proxies.each { |p| p.set_subject(value) }
        end

        def begin_fiber(&blk)
          trace(:fiber_new)
          @last_fiber = fiber = ::Fiber.new(&blk)
          fiber.resume
          fiber
        end

        def wait(target, &cantwait_proc)
          trace(:fiber_wait, target)
          if @root_fiber != ::Fiber.current
            (waiters[target] ||= []) << ::Fiber.current
            ::Fiber.yield
          else
            trace(:fiber_cantwait, target)
            cantwait_proc.call
          end
        end

        def release(target, value)
          target_waiters = waiters.delete(target) || []
          trace(:fiber_release, target, target_waiters.length)
          target_waiters.each { |f| f.resume(value) }
        end

        def trace(type, *args)
          return if !tracing?
          string = "[trace] (#{type})"
          string += " -- [#{args.inspect}]" if args.any?
          puts string
        end
      end

      # This is a minimal implementation of the Xe::Proxy class which has an
      # explicit method for trigger a resolution of the subject.
      class Proxy
        attr_reader :resolve_proc
        attr_reader :subject

        def initialize(&resolve_proc)
          @resolve_proc = resolve_proc
          @has_subject = false
        end

        def subject?
          @has_subject
        end

        def resolve
          return @subject if subject?
          set_subject(resolve_proc.call)
          @subject
        end

        def set_subject(value)
          @subject = value
          @has_subject = true
          @subject
        end

        def method_missing(method, *args, &blk)
          resolve.send(method, *args, &blk)
        end

        def ==(other)
          resolve == other
        end

        def hash
          resolve.hash
        end
      end
    end
  end
end
