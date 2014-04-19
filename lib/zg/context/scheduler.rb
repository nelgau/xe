module Zg
  class Context

    class Scheduler
      attr_reader :root_fiber
      attr_reader :waiters

      def initialize
        @root_fiber = Fiber.current
        @waiters = {}
      end

      def wait(source, id)
        id_map = (waiters[source] ||= {})
        fibers = (id_map[id] ||= [])
        fibers << Fiber.current
        Fiber.yield
      end

      def dispatch(source, id, value)
        return unless (id_map = waiters[source])
        return unless (fibers = id_map.delete(id))
        waiters.delete(source) if id_map.empty?
        fibers.each { |f| f.resume(value) }
      end
    end

  end
end
