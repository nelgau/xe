require 'simplecov'
require 'rspec/instafail'
require 'colored'

SimpleCov.start do
  add_filter 'spec'
end

# Count of randomized iterations to run.
XE_STRESS_LEVEL = 20
# Should we run the integration torture tests?
XE_RUN_TORTURE  = !ENV['NO_TORTURE']

require 'xe'

require 'support/module'
require 'support/error'
require 'support/scenario'
require 'support/gc'

require 'support/helper'
require 'support/mock'
require 'support/realizer'
require 'support/enumeration'
