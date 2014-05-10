require 'xe/tracer/base'
require 'xe/tracer/text'
require 'xe/tracer/event'

require 'logger'

module Xe
  module Tracer
    # Returns a Xe:Tracer::Base instance from a context options hash.
    def self.from_options(options)
      tracer = options[:tracer]
      case tracer
      when :stdout
        Tracer::Text.new(logger: default_logger)
      else
        tracer
      end
    end

    # Returns a logger instance that emits only the message.
    def self.default_logger
      Logger.new(STDOUT).tap do |logger|
        logger.formatter = lambda { |_, _, _, m| "#{m}\n" }
      end
    end
  end
end
