require 'spec_helper'

describe Xe::Enumerator::Strategy::Evaluator do
  include Xe::Test::Mock::Enumerator

  subject { Xe::Enumerator::Strategy::Evaluator.new(context, &value_proc) }

  # Don't use a real context here so we can test these strategy is isolation,
  # without invoking the full complexity of the gem (like scheduling, policies
  # and the loom).

  let(:context)      { new_context_mock }
  let(:value_proc)   { Proc.new { value } }
  let(:value)        { 4 }

  let(:deferrable)   { Xe::Deferrable.new }

  let(:wait_target)  { Xe::Target.new(deferrable, 0, 0) }
  let(:wait_value)   { 5 }

  let(:waiting_proc) { Proc.new { context.wait(wait_target) } }

  def dispatch_waiting_result
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

    context "when value_proc doesn't wait" do
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

      it "sets the value of the proxy after waiting" do
        result = subject.call
        dispatch_waiting_result
        expect(result.subject).to eq(wait_value)
      end
    end
  end

end
