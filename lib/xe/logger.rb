require 'logger'

require 'xe/logger/base'
require 'xe/logger/text'
require 'xe/logger/event'

module Xe
  module Logger
    # Returns a Xe:Logger::Base instance from a context options hash.
    def self.from_options(options)
      logger = options[:logger]
      case logger
      when :stdout
        Logger::Text.new
      when ::Logger
        Logger::Text.new(:logger => logger)
      else
        logger
      end
    end
  end
end
