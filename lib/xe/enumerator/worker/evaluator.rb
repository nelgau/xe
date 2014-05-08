module Xe
  class Enumerator
    module Worker
      class Evaluator < Base
        attr_reader :result

        def initialize(eval_proc)
          @eval_proc = eval_proc

          @target = Target.new(self, nil)
          @result = nil
        end

        def run
          context.loom.fiber_started!

          @result = @eval_proc.call
          context.dispatch(@target, @result)

        ensure
          context.loom.fiber_finished!
        end

        def proxy!
          context.proxy(@target, waiter_proc)
        end

        def waiter_proc
          Context::Waiter.build_value(context, @target, final_proc)
        end

        def final_proc
          Proc.new do
            context.finalize
            @result
          end
        end
      end
    end
  end
end
