require 'simplecov'
require 'rspec/instafail'
require 'colored'

SimpleCov.start do
  add_filter 'spec'
end

XE_STRESS_LEVEL = 1      # Count of randomized iterations to run
XE_RUN_TORTURE  = false  # Should we run the integration torture tests?

require 'xe'

require 'support/module'
require 'support/error'
require 'support/gc'

require 'support/mock'
require 'support/realizer'
require 'support/enumeration'
