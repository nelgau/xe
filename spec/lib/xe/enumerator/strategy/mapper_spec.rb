require 'spec_helper'

describe Xe::Enumerator::Strategy::Mapper do
  include Xe::Test::Mock::Enumerator

  subject do
    Xe::Enumerator::Strategy::Mapper.new(context, enumerable, &map_proc)
  end

  # Don't use a real context here so we can test these strategy is isolation,
  # without invoking the full complexity of the gem (like scheduling, policies
  # and the loom).

  let(:context)     { new_context_mock }
  let(:map_proc)    { double_proc }

  let(:enumerable)  { (0...6).to_a }
  let(:double_proc) { Proc.new { |i| i * 2 } }
  let(:expected)    { enumerable.map(&double_proc) }

  let(:deferrable)  { Xe::Deferrable.new }

  let(:all_wait_proc) do
    Proc.new do |index|
      value = wait_for_index(index)
      double_proc.call(value)
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
      expect(subject.enum).to eq(enumerable)
    end

    it "sets the map_proc attribute" do
      expect(subject.map_proc).to eq(map_proc)
    end

    context "when map_proc is not given" do
      let(:map_proc) { nil }

      it "raises ArgumentError" do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

  end

  describe '#call' do

    context "when map_proc doesn't wait" do
      let(:map_proc) { double_proc }

      it "returns the mapping of map_proc over the enumerable" do
        expect(subject.call).to eq(expected)
      end
    end

    context "when map_proc waits for each computation" do
      let(:map_proc) { all_wait_proc }

      it "returns a proxy in place of all results" do
        results = subject.call
        subject.results.each do |result|
          expect(is_proxy?(result)).to be_true
        end
      end

      it "sets the value of the proxy after waiting" do
        results = subject.results
        dispatch_all_wait_results
        results.each_with_index do |result, index|
          expect(result.subject).to eq(expected[index])
        end
      end
    end

  end

end
