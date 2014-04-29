require 'simplecov'
SimpleCov.start do
  add_filter 'spec'
end

require 'xe'

# Count of randomized iterations to run
STRESS_LEVEL = 50