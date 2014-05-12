module Xe
  class Enumerator
    module Strategy
      # The super class of all enumeration strategies. Strategies use the
      # context to create fibers and dispatch/proxy values for targets.
      #
      # Values are referenced by a target, constructed from the unique worker
      # instance (as the source) and sometimes by the index of the result (as
      # the id). However, unlike realizers, enumeration strategies are not
      # deferrables and their results can't be immediately accessed by the
      # context at an arbitrary time.
      #
      # Strategies must avoid using the 'liveness' property (alive?) of fibers
      # as the context may choose to keep fibers in a pool so that they live
      # beyond the execution of the entry point.
      #
      # As for formal matter, strategies are limited to calling the following
      # methods on the context: #begin_fiber, #dispatch, #proxy, #finalize!
      class Base
        attr_reader :context

        # Constructs a new instance of the strategy and invokes it.
        def self.call(*args, &blk)
          new(*args, &blk).call
        end

        def initialize(context)
          @context = context
        end

        # Returns the result of the enumeration. The return value may be an
        # arbitrary object, usually a value or an array, and may contain
        # unresolved proxies objects.
        def call
          raise NotImplementedError
        end

        def inspect
          "#<#{self.class.name}>"
        end

        def to_s
          inspect
        end
      end
    end
  end
end
