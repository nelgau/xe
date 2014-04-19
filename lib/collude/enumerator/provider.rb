module Collude
  class Enumerator
    class Provider
      include Enumerable

      attr_reader :context
      attr_reader :enumerable
      attr_reader :fibers
      attr_reader :interrupted

      def initialize(context, enumerable)
        @context = context
        @enumerable = enumerable
        @fibers = []
        @interrupted = false
      end

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

      Enumerable.instance_methods.each do |m|



      end





    end
  end
end
