module Xe::Test
  module Scenario
    # Each test will be run under these conditions and the output, be it value
    # or exception, will be compared to the serialized scenario.
    SCENARIO_OPTIONS = {
      :serialized     => { :enabled    => false },
      :one_fiber      => { :max_fibers => 1     },
      :several_fibers => { :max_fibers => 10    },
      :many_fibers    => { :max_fibers => 200   }
    }
    # The scenario with this name is used as a reference.
    REFERENCE_KEY = :serialized

    # This exception is thrown and caught by the specs. It would be unwise to
    # rescue from a very general exception like StandardError as this would
    # hide obvious flaws in the code.
    class Error < Xe::Test::Error; end

    module ClassMethods

      def expect_output!
        it "has the correct output" do
          results = run_scenarios
          Scenario.verify_results(results, :value => output)
        end
      end

      def expect_consistent!
        it "is consistent" do
          results = run_scenarios
          reference = results.delete(REFERENCE_KEY)
          Scenario.verify_results(results, reference)
        end
      end

      def expect_exception!
        it "raises an exception" do
          results = run_scenarios
          Scenario.verify_exception(results)
        end
      end

    end

    module InstanceMethods
      # Raises an exception expected by `expect_exception!`.
      def raise_exception
        raise Xe::Test::Scenario::Error
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
      base.send(:include, PrivateMethods)
    end

    module PrivateMethods

      def run_scenarios
        start_time = Time.now
        Scenario.log "Working."

        results = SCENARIO_OPTIONS.each_with_object({}) do |(name, opts), rs|
          rs[name] = run_context(opts)
          Scenario.log '.'
        end

        interval = Time.now - start_time
        Scenario.log " (completed in %0.2f seconds)\n" % interval.to_f
        Scenario.print_stats(results)
        results
      end

      def run_context(options)
        { :value => Xe.context(options) { invoke } }
      rescue => e
        { :error => e }
      end

    end

    def self.verify_results(results, reference)
      results.each do |key, result|
        if result != reference
          raise "Verification failed! Run #{key} is not correct."
        end
      end
    end

    def self.verify_exception(results)
      results.each do |key, result|
        if !result[:error] || !result[:error].is_a?(Error)
          raise "Verification failed! Run #{key} did not fail as expected."
        end
      end
    end

    # Purely for debugging and independent verification.
    def self.print_stats(results)
      results.each do |key, result|
        string = "#{key.to_s.ljust(16)} -- "
        if result[:error]
          error  = result[:error]
          string += "#{error}"
        else
          value = result[:value]
          count = count_nodes(value)
          hash = value.hash
          string += "#{count} nodes, hash = #{hash}"
        end
        log "#{string}\n"
      end
    end

    def self.count_nodes(results)
      # If results is a Hash, only consider it's values.
      results = results.values if results.is_a?(Hash)
      # Recurse into enumerables, or return 1 for objects.
      results.respond_to?(:each) ?
        results.inject(0) { |s, x| s += count_nodes(x) } :
        1
    end

    def self.log(string)
      print string.cyan
    end
  end
end
