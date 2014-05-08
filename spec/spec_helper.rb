require 'simplecov'
require 'rspec/instafail'
require 'colored'

SimpleCov.start do
  add_filter 'spec'
end

# Count of randomized iterations to run
XE_STRESS_LEVEL = 1

require 'xe'

# Xe.configure do |c|
#   c.logger = :stdout
# end

require 'support/module'
require 'support/gc'

require 'support/mock'
require 'support/realizer'
require 'support/enumeration'
