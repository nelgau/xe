module Xe
  class Context
    module Waiter

      def self.build_value(context, target, immediate_proc)
        Proc.new do
          context.wait(target) do
            immediate_proc.call
          end
        end
      end

      def self.build_realize(context, target)
        Proc.new do

          puts "A".magenta

          context.wait(target) do

            puts "B".magenta

            context.realize_target(target)
          end
        end
      end

    end
  end
end