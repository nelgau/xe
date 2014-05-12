module Xe
  module Profile
    module Benchmark
      extend Enumerable

      # Returns a hash mapping benchmark names to classes.
      def self.all_benchmarks
        @all_benchmarks ||= {}
      end

      def self.each(&blk)
        all_benchmarks.each(&blk)
      end

      class Base
        # Register this class as the benchmark of the given name.
        def self.register_as(name)
          Xe::Profile::Benchmark.all_benchmarks[name] ||= self
        end

        # Returns a description of the benchmark.
        def self.description
          "No description!"
        end

        # Construct an instance and run the benchmark.
        def self.call
          new.call
        end

        # Run the benchmark.
        def call
          raise NotImplementedError
        end
      end
    end
  end
end

# Import all the classes within profile/benchmarks.
Dir[File.expand_path("../benchmark/**/*.rb", __FILE__)].each { |f| require f }
