module Xe
  class Enumerator
    module Strategy
      # The super class of all enumeration strategies. Strategies use the
      # context via a worker instance to create fibers and dispatch/proxy
      # values for targets.
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
