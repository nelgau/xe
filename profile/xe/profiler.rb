require 'benchmark'
require 'ruby-prof'
require 'colored'

require 'xe/profiler/aggregating_printer'

module Xe
  class Profiler
    # Creates an instance and runs the profiler.
    def self.call
      new.call
    end

    def call
      benchmarks = Xe::Benchmark.all_benchmarks
      benchmarks.each do |name, klass|
        run(name, klass)
      end
    end

    def run(name, klass)
      print "\n"
      print "***** BENCHMARK -- #{titleize(name)} *****\n\n".magenta

      # Run the benchmark two times to warm up.
      2.times { klass.call }
      # The author of ruby-prof recommends this for accurate benchmarking.
      sleep 2

      print "Runtime:\n\n"
      run_benchmark(klass)

      print "\nProfiling:\n\n"
      run_profile(klass)

      print "\n"
    end

    def run_benchmark(klass)
      instance = klass.new
      ::Benchmark.bm(4) do |x|
        x.report("total:") { instance.call }
      end
    end

    def run_profile(klass)
      instance = klass.new
      result = RubyProf.profile { instance.call }
      AggregatingPrinter.new(result).print
    end

    def titleize(string)
      string.to_s.gsub('_', ' ').split(/(\W)/).map(&:capitalize).join
    end
  end
end
