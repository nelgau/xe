module Xe
  class Configuration
    # Set this to false to realize all deferrals immediately.
    attr_accessor :enabled
    # Maximum number of fibers that the context will run concurrently.
    attr_accessor :max_fibers
    # An instance of Xe::Logger::Base that receives events from the context.
    attr_accessor :logger

    def initialize
      @enabled = true
      @max_fibers = 50
      @logger = nil
    end

    # Returns a hash of default options for new contexts.
    def context_options
      return {
        :enabled => enabled,
        :max_fibers => max_fibers,
        :logger => logger
      }
    end
  end
end
