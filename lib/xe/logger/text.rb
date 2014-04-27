require 'logger'

module Xe
  module Logger
    class Text
      attr_reader :logger

      def initialize(options={})
        @logger = options[:logger] || default_logger
      end

      def call(event, *args)
        send(event, *args)
      end

      private

      def finalize_start
        log "Finalizing context."
      end

      def finalize_step(group_count, item_count)
        log "Finalizing #{group_count} group(s) with #{item_count} id(s)."
      end

      def finalize_deadlock
        log "Deadlocked."
      end

      def value_cached(source, id)
        log "[#{source}, #{id}] Using cached value."
      end

      def value_deferred(source, id)
        log "[#{source}, #{id}] Deferring evaluation."
      end

      def value_dispatched(source, id)
        log "[#{source}, #{id}] Dispatching value."
      end

      def value_realized(realizer, id)
        log "[#{realizer}, #{id}] Realized value."
      end

      def value_forced(realizer, id)
        log "[#{realizer}, #{id}] Forced realization."
      end

      def fiber_new
        log "Creating fiber."
      end

      def fiber_wait(source, id)
        log "[#{source}, #{id}] Fiber waiting."
      end

      def fiber_release(source, id, count)
        log "[#{source}, #{id}] Releasing #{count} fiber(s)."
      end

      def proxy_new(source, id)
        log "[#{source}, #{id}] Creating proxy."
      end

      def proxy_resolve(source, id, count)
        log "[#{source}, #{id}] Resolving #{count} proxie(s)."
      end

      def log(string)
        logger.info(string)
      end

      def default_logger
        ::Logger.new(STDOUT).tap do |logger|
          logger.formatter = lambda { |_, _, _, m| "#{m}\n" }
        end
      end
    end
  end
end
