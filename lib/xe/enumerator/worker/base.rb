module Xe
  class Enumerator
    module Worker
      class Base
        def run
          raise NotImplementedError
        end

        def proxy!
          raise NotImplementedError
        end

        protected

        def context
          Context.current
        end
      end
    end
  end
end
