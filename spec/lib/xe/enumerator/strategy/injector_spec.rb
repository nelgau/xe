require 'spec_helper'

describe Xe::Enumerator::Strategy::Injector do
  include Xe::Test::Mock::Enumerator

  subject do
    Xe::Enumerator::Strategy::Injector.new(
      context,
      enumerable,
      initial,
      &inject_proc
    )
  end

  # Don't use a real context here so we can test these strategy is isolation,
  # without invoking the full complexity of the gem (like scheduling, policies
  # and the loom).

  let(:context)     { new_context_mock }
  let(:inject_proc) { sum_proc }

  let(:enumerable)  { (0...6).to_a }
  let(:initial)     { 22 }
  let(:sum_proc)    { Proc.new { |acc, i| acc + i } }
  let(:expected)    { enumerable.inject(initial, &sum_proc) }

  let(:deferrable)  { Xe::Deferrable.new }

  let(:all_wait_proc) do
    Proc.new do |acc, index|
      value = wait_for_index(index)
      sum_proc.call(acc, value)
    end
  end

  def target_for_index(index)
    Xe::Target.new(deferrable, index, 0)
  end

  def wait_for_index(index)
    context.wait(target_for_index(index))
  end

  def dispatch_for_index(index)
    target = target_for_index(index)
    context.dispatch(target, index)
  end

  def dispatch_all_wait_results
    enumerable.each { |index| dispatch_for_index(index) }
  end

  describe '#initialize' do

    it "delegates to super to set the context" do
      expect(subject.context).to eq(context)
    end

    it "sets the enumerable attribute" do
      expect(subject.enumerable).to eq(enumerable)
    end

    it "sets the inject_proc attribute" do
      expect(subject.inject_proc).to eq(inject_proc)
    end

    context "when inject_proc is not given" do
      let(:inject_proc) { nil }

      it "raises ArgumentError" do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

  end

  describe '#call' do

    context "when map_proc doesn't wait" do
      let(:inject_proc) { sum_proc }

      it "returns the fold of inject_proc over the enumerable" do
        expect(subject.call).to eq(expected)
      end
    end

    context "when inject_proc waits for each computation" do
      let(:inject_proc) { all_wait_proc }

      it "returns a proxy in place of all results" do
        result = subject.call
        expect(is_proxy?(result)).to be_true
      end

      it "sets the value of the proxy after waiting" do
        result = subject.call
        dispatch_all_wait_results
        expect(result.subject).to eq(expected)
      end
    end

  end

end
