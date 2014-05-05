require 'spec_helper'

describe "Xe - Randomized Enumeration Topology" do

  let(:options) { {
    :max_fibers => 10
  } }

  def self.depths
    [1, 2, 4, 8]
  end

  class DistinctValuesError < StandardError
    def initialize(reference, style, seed)
      super("Enumeration '#{style}' is distinct from '#{reference}' (#{seed})")
    end
  end

  def run_all_styles(root)
    Xe::Test::Enumeration.styles.each_with_object({}) do |style, results|
      results[style] = Xe::Test::Enumeration.run!(style, root, options)
    end
  end

  def run_and_verify(root, seed)
    results = run_all_styles(root)
    reference_style = results.keys.first
    reference_value = results.delete(reference_style)
    results.each do |style, value|
      if value != reference_value
        raise DistinctValuesError.new(reference_style, style, seed)
      end
    end
  end

  depths.each do |context_depth|
    context "with an enumeration depth of #{context_depth}" do
      let(:depth) { context_depth }

      describe "consistently enumerates randomized topologies" do

        XE_STRESS_LEVEL.times do |attempt|
          it "is consistent (attempt #{attempt + 1})" do
            factory = Xe::Test::Enumeration::Random.new(:max_depth => depth)
            run_and_verify(factory.build, factory.seed)
          end
        end

      end
    end
  end

end
