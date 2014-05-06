require 'simplecov'
require 'rspec/instafail'
require 'colored'

SimpleCov.start do
  add_filter 'spec'
end

# Count of randomized iterations to run
XE_STRESS_LEVEL = 1

require 'xe'

require 'support/module'
require 'support/matchers'
require 'support/mock'
require 'support/realizer'
require 'support/enumeration'
