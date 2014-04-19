module Collude
  class Enumerator
    class Fiber
      def self.begin(enumerable, results, &block)
        new { |f| block.call(e.next) while f.running? }
      end

      def running?
        @running
      end

      def stop!
        @running = false
      end
    end
  end
end
