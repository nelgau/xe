require 'colored'

module Xe
  module Profile
    class Stress
      # Creates an instance and runs the allocation tracker.
      def self.call
        new.call
      end

      def initialize
        @last_stats = @stats = get_stats
        @runs = 0
      end

      def call
        banner_start
        loop do
          run_benchmarks
          GC.start
          next_stats
          print_stats
        end
      end

      def run_benchmarks
        Xe::Profile::Benchmark.all_benchmarks.each { |_, cl| cl.call }
      end

      def next_stats
        @last_stats = @stats
        @stats = get_stats
        @runs += 1
      end

      def get_stats
        counts = ObjectSpace.count_objects
        rss = `ps -o rss= -p #{Process.pid}`.chomp.to_i
        return {
          :total_objects => counts[:TOTAL],
          :free_objects  => counts[:FREE],
          :rss           => rss
        }
      end

      def banner_start
        print "\n"
        print "Xe Stress Test (v#{Xe::VERSION})\n\n"
      end

      def print_stats
        strings = @stats.keys.map do |key|
          last = @last_stats[key]
          now  = @stats[key]
          delta = (now.to_f - last.to_f) / last.to_f
          delta_string = "%+0.2f%" % delta
          delta_string = delta_string.red if delta > 0
          "#{key}: #{now} (#{delta_string})"
        end
        puts "Run #{"%08d" % @runs}: #{strings.join("\t")}"
      end
    end
  end
end
