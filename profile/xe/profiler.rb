require 'benchmark'
require 'ruby-prof'
require 'colored'

require 'xe/profiler/aggregating_printer'

module Xe
  class Profiler
    # These methods show up in the profiles but don't actually contribute to
    # our understand on where the hotspots are. Remove them and assign their
    # timings to the parent.
    IGNORED_METHODS = [
      /Kernel#loop/
    ]

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
      banner(name, klass)
      prepare(name, klass)
      benchmark(name, klass)
      profile(name, klass)
      print "\n"
    end

    def banner(name, klass)
      print "\n"
      hrule = "-" * 20
      print "#{hrule} #{titleize(name)} #{hrule}\n\n".bold
      print "#{klass.description}\n"
    end

    def prepare(name, klass)
      # Run the benchmark two times to warm up.
      2.times { klass.call }
      # The author of ruby-prof recommends this for accurate benchmarking.
      sleep 2
    end

    def benchmark(name, klass)
      print "\nBenchmark:\n\n"
      instance = klass.new
      ::Benchmark.bm(4) do |x|
        x.report("total:") { instance.call }
      end
    end

    def profile(name, klass)
      print "\nProfiling:\n\n"
      instance = klass.new
      result = RubyProf.profile { instance.call }
      result.eliminate_methods!(IGNORED_METHODS)
      AggregatingPrinter.new(result).print
    end

    def titleize(string)
      string.to_s.gsub('_', ' ').split(/(\W)/).map(&:capitalize).join
    end
  end
end
