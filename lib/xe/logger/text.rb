require 'logger'

module Xe
  module Logger
    class Text < Base
      attr_reader :logger

      def initialize(options={})
        @logger = options[:logger] || default_logger
      end

      private

      def event_realize(event)
        log "#{event}: Realizing #{event.length} values."
      end

      def value_cached(target)
        log "#{target}: Using cached value."
      end

      def value_deferred(target)
        log "#{target}: Deferring evaluation."
      end

      def value_dispatched(target)
        log "#{target}: Dispatching value."
      end

      def value_realized(target)
        log "#{target}: Realized value."
      end

      def value_forced(target)
        log "#{target}: Forced realization."
      end

      def fiber_new
        log "Creating fiber."
      end

      def fiber_wait(target)
        log "#{target}: Attempting to yield from fiber."
      end

      def fiber_release(target, count)
        log "#{target}: Releasing #{count} fiber(s)."
      end

      def fiber_free(event)
        log "#{event}: Reached maximum fiber count. Realizing event."
      end

      def proxy_new(target)
        log "#{target}: Creating proxy."
      end

      def proxy_resolve(target, count)
        log "#{target}: Resolving value proxied #{count} time(s)."
      end

      def finalize_start
        log "Finalizing context."
      end

      def finalize_step(event)
        log "Finalizing event with #{event.length} values."
      end

      def finalize_deadlock
        log "Deadlocked."
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
