require 'logger'

require 'xe/logger/base'
require 'xe/logger/text'
require 'xe/logger/event'

module Xe
  module Logger
    def self.from_option(option)
      case option
      when :stdout
        Logger::Text.new
      when Logger
        Logger::Text.new(:logger => option)
      else
        option
      end
    end
  end
end
