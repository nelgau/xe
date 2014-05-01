require 'xe/logger/base'
require 'xe/logger/text'
require 'xe/logger/event'

module Xe
  module Logger
    def self.from_option(option)
      option == :stdout ? Logger::Text.new : option
    end
  end
end
