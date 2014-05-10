module Xe
  class Enumerator
    module Worker
      class Evaluator < Base
        attr_reader :eval_proc
        attr_reader :target
        attr_reader :result

        def initialize(&eval_proc)
          @eval_proc = eval_proc
          @target = Target.new(self)
          @result = nil
        end

        def run
          @result = @eval_proc.call
          context.dispatch(@target, @result)
        end

        def proxy!
          context.proxy(@target) do
            context.finalize!
            @result
          end
        end
      end
    end
  end
end
