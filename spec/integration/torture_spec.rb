require 'spec_helper'

describe 'Xe - Torture Tests' do

  let(:scenarios) { {
    :serialized     => { :enabled    => false },
    :one_fiber      => { :max_fibers => 1     },
    :several_fibers => { :max_fibers => 10    },
    :many_fibers    => { :max_fibers => 200   }
  } }

  Xe::Test::Realizer.torture.each do |realizer|
    context "when evaluating #{realizer.class}" do

      let(:value) { realizer[1] }

      it "is consistent" do
        results = run_scenarios
        print_stats(results)
        verify_results(results)
      end

      def run_realization(options={})
        Xe.context(options) { value }
      end

      def run_scenarios
        start_time = Time.now
        log "Working."

        results = scenarios.each_with_object({}) do |(name, opts), rs|
          rs[name] = run_realization(opts)
          log '.'
        end

        interval = Time.now - start_time
        log " (completed in %0.2f seconds)\n" % interval.to_f
        results
      end

      def verify_results(results)
        reference_key = results.keys.first
        reference_value = results.delete(reference_key)
        results.each do |key, value|
          if value != reference_value
            raise "Test failed! #{key} is inconsistent with #{reference_key}"
          end
        end
      end

      # Purely for debugging and independent verification.
      def print_stats(results)
        results.each do |key, value|
          count = count_nodes(value)
          hash = value.hash
          log "#{key.to_s.ljust(16)} -- #{count} nodes, hash = #{hash}\n"
        end
      end

      def count_nodes(results)
        # If results is a Hash, only consider it's values.
        results = results.values if results.is_a?(Hash)
        # Recurse into enumerables, or return 1 for objects.
        results.respond_to?(:each) ?
          results.inject(0) { |s, x| s += count_nodes(x) } :
          1
      end

      def log(string)
        print string.cyan
      end

    end
  end

end
