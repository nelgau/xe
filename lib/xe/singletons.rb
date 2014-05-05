module Xe
  module Singletons
    # Instantiates and returns the singleton configuration object.
    def config
      @config ||= Configuration.new
    end
  end
end
