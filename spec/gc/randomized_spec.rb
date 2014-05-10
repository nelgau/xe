require 'spec_helper'

describe "Xe - Garbage Collection (Randomized)" do
  include Xe::Test::GC

  let(:options) { {
    :max_fibers => 20
  } }

  def self.depths
    [1, 2, 4, 6]
  end

  depths.each do |context_depth|
    context "with an enumeration depth of #{context_depth}" do
      let(:depth) { context_depth }

      XE_STRESS_LEVEL.times do |attempt|
        define_test!(
          name: "holds no references (attempt #{attempt + 1})",
          has_output: false
        )

        def invoke
          factory = Xe::Test::Enumeration::Random.new(max_depth: depth)
          Xe::Test::Enumeration.run!(:context, factory.build, options)
        end
      end

    end
  end

end
