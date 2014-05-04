require 'simplecov'
SimpleCov.start { add_filter 'spec' }

# Count of randomized iterations to run
XE_STRESS_LEVEL = 0
XE_NO_SINGLETON_PROXY = true

require 'xe'
require 'support/base'
require 'support/mock'
