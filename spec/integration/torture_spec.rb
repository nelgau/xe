require 'spec_helper'

if XE_RUN_TORTURE
  describe 'Xe - Torture Tests' do
    include Xe::Test::Scenario

    before do
      scenario_debug!
    end

    Xe::Test::Realizer.torture.each do |realizer|
      context "when evaluating #{realizer.class}" do
        expect_consistent!

        let(:value) { realizer[1] }

        def invoke
          value
        end
      end
    end

  end
end
