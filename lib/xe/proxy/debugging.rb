require 'logger'

module Xe
  class Proxy < BasicObject
    module Debugging
      class << self
        # The logger instance to which debug output is written.
        attr_accessor :logger
      end

      MAX_INSPECT_LENGTH = 20
      UNTRACABLE_METHODS = [
        :object_id,
        :__send__,
        :__id__,
        # Tracing this method will cause an infinite regress. There's a
        # solution of course, but it's not worth the effort and complexity.
        :__xe_proxy?
      ]

      def self.included(base)
        # Set a default logger if none exists.
        @logger ||= default_logger
        # For each tracable instance method, monkey patch it to invoke .emit.
        tracable_methods(base).each do |method|
          aliased_method = original_method_name(method)
          base.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            alias :#{aliased_method} :#{method}
            def #{method}(*args, &blk)
              ::Xe::Proxy::Debugging.emit(self, :#{method}, args, &blk)
              #{aliased_method}(*args, &blk)
            end
          RUBY
        end
      end

      def self.emit(receiver, method, args, &blk)
        method_just  = method.to_s.ljust(17)
        receiver_str = inspect_object(receiver)
        args_str     = args.map { |x| inspect_object(x) }
        blk_str      = block_given? ? "(blk)" : ''
        logger.info "#{receiver_str}: " \
                    "#{method_just} #{blk_str}#{args_str.inspect}"
      end

      def self.tracable_methods(klass)
        klass.instance_methods - UNTRACABLE_METHODS
      end

      def self.call_original(obj, method, *args, &blk)
        aliased_method = original_method_name(method)
        obj.__send__(aliased_method, *args, &blk)
      end

      def self.original_method_name(method)
        "#{clean_method_name(method)}_without_debugging"
      end

      def self.clean_method_name(method)
        method = method.to_s
        method.gsub!('!', 'ex')
        method.gsub!('=', 'eq')
        method.gsub!('?', 'qu')
        method
      end

      def self.inspect_object(obj)
        ::Xe::Proxy.proxy?(obj) ?
          inspect_proxy(obj) :
          inspect_value(obj)
      end

      def self.inspect_proxy(proxy)
        "#<Xe::Proxy id: #{proxy_id_as_hex(proxy)} -> #{proxy_state(proxy)}>"
      end

      def self.inspect_value(value)
        value.inspect[0...MAX_INSPECT_LENGTH]
      end

      def self.proxy_id_as_hex(proxy)
        '%016x' % call_original(proxy, :__proxy_id)
      end

      def self.proxy_state(proxy)
        case
        when call_original(proxy, :__value?)    then '[value]'
        when call_original(proxy, :__resolved?) then '[proxy]'
        else                                         '[     ]'
        end
      end

      def self.default_logger
        ::Logger.new(STDOUT).tap do |logger|
          logger.formatter = lambda { |_, _, _, m| "#{m}\n" }
        end
      end
    end
  end
end
