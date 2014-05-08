module Xe
  module Singletons
    # Instantiates and returns the singleton configuration object.
    def config
      @config ||= Configuration.new
    end

    # Synonym for the current context.
    def current
      Context.current
    end
  end
end
