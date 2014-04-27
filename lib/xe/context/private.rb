module Xe
  class Context
    module Private
      attr_reader :logger
      attr_reader :queue
      attr_reader :manager
      attr_reader :proxies
      attr_reader :cache

      def initialize(options={})
        @logger = logger_from_option(options[:logger])
        @queue = Queue.new(&method(:post_realize))
        @manager = Manager.new
        @proxies = {}
        @cache = {}
      end

      # @private
      def logger_from_option(option)
        option == :stdout ? Logger::Text.new : option
      end

      # @private
      def log(*args)
        @logger && @logger.call(*args)
      end

      # @private
      def post_realize(realizer, id, value)
        key = [realizer, id]
        log(:value_realized, realizer, id)
        cache[key] = value
        dispatch(realizer, id, value)
      end

      # @private
      def dispatch(source, id, value)
        log(:value_dispatched, source, id)
        key = [source, id]
        resolve(key, value)
        release(key, value)
      end

      # @private
      def fiber(&blk)
        log(:fiber_new)
        manager.fiber(&blk)
      end

      # @private
      def wait(key, &blk)
        log(:fiber_wait, *key)
        manager.wait(key, &blk)
      end

      # @private
      def release(key, value, &blk)
        log(:fiber_release, *key, manager.waiter_count(key))
        manager.release(key, value)
      end

      # @private
      def proxy(source, id, &blk)
        key = [source, id]
        log(:proxy_new, source, id)
        proxy = Proxy.new { wait(key, &blk) }
        (proxies[key] ||= []) << proxy
        proxy
      end

      # @private
      def resolve(key, value)
        key_proxies = proxies[key]
        return unless key_proxies
        log(:proxy_resolve, *key, key_proxies.count)
        key_proxies.each { |p| p.__set_target(value) }
      end
    end
  end
end
