require 'spec_helper'

describe 'Xe - Enumeration (Realization)' do

  include Xe::Test::Scenario

  let(:scenario_options) { {
    :serialized     => { :enabled    => false },
    :one_fiber      => { :max_fibers => 1     },
    :several_fibers => { :max_fibers => 10    },
    :many_fibers    => { :max_fibers => 200   }
  } }

  let(:realizer) do
    Xe.realizer do |xs|
      xs.map { |x| x + 1 }
    end
  end

  context "when realizing outside of an enumerator" do

    context "with a single-valued enumerator" do
      context "when returning values" do
        expect_output!

        let(:input)  { [1, 2, 3] }
        let(:output) { 9 }

        def invoke
          Xe.context do |c|
            result = c.enum(input).inject(0) do |sum, x|
              sum + realizer[x]
            end
            result.to_i
          end
        end
      end
    end

    context "with a mapping enumerator" do
      context "when returning values" do
        expect_output!

        let(:input)  { [1, 2, 3] }
        let(:output) { [2, 3, 4] }

        def invoke
          Xe.context do |c|
            result = c.enum(input).map do |x|
              realizer[x]
            end
            result.map do |x|
              x.to_i
            end
          end
        end
      end
    end

  end

end
