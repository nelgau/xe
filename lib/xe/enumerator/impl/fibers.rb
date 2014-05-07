module Xe
  class Enumerator
    module Impl
      module Fibers
        # Returns a hash from implementations to fibers.
        def self.all
          @all ||= {}
        end

        # Returns the active fiber for an implementation.
        def self.[](impl)
          all[impl]
        end

        # Assign an active fiber to an implementation.
        def self.[]=(impl, fiber)
          all[impl] = fiber
        end

        # Drop the reference to an implementation's active fiber.
        def self.drop(impl)
          all.delete(impl)
        end
      end
    end
  end
end
