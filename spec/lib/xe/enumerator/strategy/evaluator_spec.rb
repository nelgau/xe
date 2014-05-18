require 'spec_helper'

describe Xe::Enumerator::Strategy::Evaluator do
  include Xe::Test::Helper::Enumerator
  include Xe::Test::Mock::Enumerator

  subject do
    Xe::Enumerator::Strategy::Evaluator.new(context, &value_proc)
  end

  let(:value_proc)   { nowait_proc }

  let(:nowait_proc)  { Proc.new { value } }
  let(:value)        { 4 }

  let(:waiting_proc) { Proc.new { context.wait(wait_target) } }
  let(:wait_target)  { Xe::Target.new(deferrable, 0, 0) }
  let(:wait_value)   { 5 }

  def release_waiter
    context.dispatch(wait_target, wait_value)
  end

  describe '#initialize' do

    it "delegates to super to set the context" do
      expect(subject.context).to eq(context)
    end

    it "sets the value_proc attribute" do
      expect(subject.value_proc).to eq(value_proc)
    end

    context "when value_proc is not given" do
      let(:value_proc) { nil }

      it "raises ArgumentError" do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

  end

  describe '#call' do

    context "when the context is enabled" do
      let(:enabled) { true }

      context "when value_proc doesn't wait" do
        let(:value_proc)   { nowait_proc }

        it "returns the expected result" do
          expect(subject.call).to eq(value)
        end
      end

      context "when value_proc waits" do
        let(:value_proc) { waiting_proc }

        it "returns a proxy in place of the result" do
          result = subject.call
          expect(is_proxy?(result)).to be_true
        end

        it "sets the value of the proxy after releasing" do
          result = subject.call
          release_waiter
          expect(result.subject).to eq(wait_value)
        end
      end
    end

    context "when the context is disabled" do
      let(:enabled) { false }

      before do
        expect_serial!
      end

      context "when value_proc doesn't wait" do
        let(:value_proc) { nowait_proc }

        it "returns the expected result" do
          expect(subject.call).to eq(value)
        end
      end
    end

  end

end
