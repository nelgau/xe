module Xe
  class Enumerator
    module Worker
      class Evaluator < Base
        attr_reader :result

        def initialize(eval_proc)
          @eval_proc = eval_proc
          @result = nil
        end

        def run
          context.loom.fiber_started!

          @result = @eval_proc.call
          target = Target.new(self, nil)
          context.dispatch(nil, @result)
        ensure
          context.loom.fiber_finished!
        end

        def proxy!
          target = Target.new(self, nil)
          proxy = Enumerator::Proxy.new(context, target, final_proc)
          context.add_proxy(@target, proxy)
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
