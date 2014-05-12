require 'benchmark'
require 'ruby-prof'
require 'colored'

require 'xe/profiler/aggregating_printer'

module Xe
  module Profile
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

      def initialize
        # If we were given a brenchmark name, only run that one.
        @run_name = ARGV.shift
      end

      def call
        banner_start
        Xe::Profile::Benchmark.each do |name, klass|
          next if @run_name && @run_name != name.to_s
          run(name, klass)
        end
      end

      def run(name, klass)
        banner_separator(name, klass)
        prepare(name, klass)
        benchmark(name, klass)
        profile(name, klass)
        print "\n"
      end

      def banner_start
        print "\n"
        print "Xe Profiler (v#{Xe::VERSION})\n"
      end

      def banner_separator(name, klass)
        print "\n"
        hrule = "-" * 20
        print "#{hrule} #{klass.name} #{hrule}\n\n".bold
        print "#{klass.description}\n\n"
      end

      def prepare(name, klass)
        print "Warming up."
        # Run the benchmark two times to warm up.
        2.times { klass.call; print '.' }
        # The author of ruby-prof recommends this for accurate benchmarking.
        sleep 2
        print "\n"
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
    end
  end
end
