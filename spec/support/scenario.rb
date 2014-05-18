module Xe::Test
  module Scenario
    # Each test will be run under these conditions and the output, be it value
    # or exception, will be compared to the serialized scenario.
    DEFAULT_SCENARIO_OPTIONS = {
      :serialized     => { :enabled    => false },
      :one_fiber      => { :max_fibers => 1     },
      :several_fibers => { :max_fibers => 10    },
      :many_fibers    => { :max_fibers => 200   }
    }
    # The scenario with this name is used as a reference.
    DEFAULT_REFERENCE_KEY = :serialized

    # This exception is thrown and caught by the specs. It would be unwise to
    # rescue from a very general exception like StandardError as this would
    # hide obvious flaws in the code.
    class Error < Xe::Test::Error; end

    module ClassMethods

      def expect_success!(options={})
        define_test("runs without raising", options) do
          run_scenarios
        end
      end

      def expect_output!(options={})
        define_test("has the correct output", options) do
          results = run_scenarios
          Scenario.verify_results(results, :value => output)
        end
      end

      def expect_consistent!(options={})
        define_test("is consistent", options) do
          results = run_scenarios
          reference = results.delete(reference_key)
          Scenario.verify_results(results, reference)
        end
      end

      def expect_exception!(options={})
        define_test("raises an exception", options) do
          results = run_scenarios
          Scenario.verify_exception(results)
        end
      end

      private

      def define_test(default_name, options={}, &blk)
        it(options[:name] || default_name, &blk)
      end

    end

    module InstanceMethods
      # Wraps the invocation of #invoke and returns the result. The default
      # implementation createds a real context.
      def around_invoke(options={})
        Xe.context(options) { yield }
      end

      # Raises an exception expected by `expect_exception!`.
      def raise_exception
        raise Xe::Test::Scenario::Error
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
      base.send(:include, PrivateMethods)

      base.class_exec do
        let(:scenario_options) { DEFAULT_SCENARIO_OPTIONS }
        let(:reference_key)    { DEFAULT_REFERENCE_KEY }
      end
    end

    module PrivateMethods

      def run_scenarios
        start_time = Time.now
        Scenario.log "Working."

        results = scenario_options.each_with_object({}) do |(name, opts), rs|
          rs[name] = run_test_driver(opts.dup)
          Scenario.log '.'
        end

        interval = Time.now - start_time
        Scenario.log " (completed in %0.2f seconds)\n" % interval.to_f
        Scenario.print_stats(results)
        results
      end

      def run_test_driver(options={})
        # Record a result value.
        value = around_invoke(options) { |*args| invoke(*args) }
        { :value => value }
      rescue => e
        # Record an exception.
        { :error => e }
      end

    end

    def self.verify_results(results, reference)
      results.each do |key, result|
        if result != reference
          explain_string = explain_value(result, reference)
          raise "Verification failed! Run #{key} #{explain_string}."
        end
      end
    end

    def self.verify_exception(results)
      results.each do |key, result|
        if !result[:error] || !result[:error].is_a?(Error)
          explain_string = explain_error(result)
          raise "Verification failed! Run #{key} #{explain_string}."
        end
      end
    end

    def self.explain_value(result, reference)
      error = result[:error]
      error ?
        "had an error when a value was expected: #{error_string(error)}" :
        "has a distinct value"
    end

    def self.explain_error(result)
      error = result[:error]
      error ?
        "had a distinct error: #{error_string(error)}" :
        "had a value when an error was unexpected"
    end

    def self.error_string(error)
      "#{error}\n#{error.backtrace.join("\n")}"
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
