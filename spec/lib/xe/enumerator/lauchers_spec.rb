require 'spec_helper'

describe Xe::Enumerator::Launchers do
  include Xe::Test::Mock::Enumerator

  subject do
    Xe::Enumerator.new(context, enumerable)
  end

  let(:context) { new_context_mock(options) }
  let(:options) { { :enabled => enabled } }
  let(:enabled) { true }

  let(:enumerable) { [1, 2, 3, 4] }

  describe '#run_evaluator' do

    let(:eval_proc) { Proc.new { value } }
    let(:value)     { 5 }

    def invoke
      subject.run_evaluator(&eval_proc)
    end

    context "when the context is enabled" do
      let(:enabled) { true }

      it "returns the value" do
        expect(invoke).to eq(value)
      end
    end

    context "when the context is disabled" do
      let(:enabled) { false }

      it "returns the value" do
        expect(invoke).to eq(value)
      end
    end

  end

  describe '#run_mapper' do

    let(:map_proc) { Proc.new { |x| x + 3 } }
    let(:results)  { enumerable.map(&map_proc) }

    def invoke
      subject.run_mapper(&map_proc)
    end

    context "when the context is enabled" do
      let(:enabled) { true }

      it "returns the expected results" do
        expect(invoke).to eq(results)
      end
    end

    context "when the context is disabled" do
      let(:enabled) { false }

      it "returns the expected results" do
        expect(invoke).to eq(results)
      end
    end

  end

  describe '#run_injector' do

    let(:initial)     { 10 }
    let(:inject_proc) { Proc.new { |acc, x| acc + x } }
    let(:results)     { enumerable.inject(initial, &inject_proc) }

    def invoke
      subject.run_injector(initial, &inject_proc)
    end

    context "when the context is enabled" do
      let(:enabled) { true }

      it "returns the expected results" do
        expect(invoke).to eq(results)
      end
    end

    context "when the context is disabled" do
      let(:enabled) { false }

      it "returns the expected results" do
        expect(invoke).to eq(results)
      end
    end

  end

end
