module Zg
  class Context
    class Scheduler
      attr_reader :waiters

      def initialize
        @waiters = {}
      end

      def sources
        waiters.keys
      end

      def ids_for_source(source)

      end

      def wait(source, id)
        id_map = (waiters[source] ||= {})
        fibers = (id_map[id] ||= [])
        fibers << Fiber.current
        Fiber.yield
      end

      def dispatch_many(source, id_value_map)
        return unless (id_map = waiters[source])
        id_value_map.each do |id, value|
          next unless (fibers = id_map.delete(id))
          fibers.each { |f| f.resume(value) }
        end
      end

    end
  end
end
