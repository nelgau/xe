# Import all the classes within spec/support/mocks.
Dir[File.expand_path("../mock/**/*.rb", __FILE__)].each { |f| require f }
