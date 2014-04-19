require 'support/enumeration/unit'
require 'support/enumeration/random'
require 'support/enumeration/runner'

module Xe::Test
  module Enumeration
    # Mapping from symbols to enumeration runners.
    RUNNERS = {
      :standard  => Runner::Standard,
      :immediate => Runner::Immediate,
      :context   => Runner::Context
    }

    def self.styles
      RUNNERS.keys
    end

    def self.run!(style, root, options)
      RUNNERS[style].run!(root, options)
    end
  end
end
