module Zg
  class Enumerator
    module Provider

      class General
        include Enumerable

        def each(&block)
          items = enumerable.to_a
          enum = Enumerator.new(enumerable)


          context.push_enumerator(self) do
            begin
              loop do
                fiber = Enumerator::Fiber.begin(enum, items, &block)
                fibers << fiber
                fiber.resume(fiber)
                # Iteration was interrupted by an unrealized value.
                @interrupted = true
              end
            rescue StopIteration
              # Interation completed.
            end
          end
          items
        end

      end

    end
  end
end
