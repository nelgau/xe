require 'spec_helper'

describe Xe::Enumerator::Strategy::Injector do
  include Xe::Test::Helper::Enumerator
  include Xe::Test::Mock::Enumerator

  subject do
    Xe::Enumerator::Strategy::Injector.new(
      context,
      enumerable,
      initial,
      &inject_proc
    )
  end

  let(:inject_proc) { sum_proc }

  let(:initial)  { 22 }
  let(:sum_proc) { Proc.new { |acc, i| acc + i } }
  let(:expected) { enumerable.inject(initial, &sum_proc) }

  let(:all_wait_proc) do
    Proc.new do |acc, index|
      value = wait_for_index(index)
      sum_proc.call(acc, value)
    end
  end

  describe '#initialize' do

    it "delegates to super to set the context" do
      expect(subject.context).to eq(context)
    end

    it "sets the enum attribute" do
      expect(subject.enum).to eq(enumerable)
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

    context "when the context is enabled" do
      let(:enabled) { true }

      context "when inject_proc doesn't wait" do
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

        it "sets the value of the proxy after releasing" do
          result = subject.call
          release_enumerable_waiters
          expect(result.subject).to eq(expected)
        end
      end
    end

    context "when the context is disabled" do
      let(:enabled) { false }

      before do
        expect_serial!
      end

      context "when inject_proc doesn't wait" do
        let(:inject_proc) { sum_proc }

        it "returns the fold of inject_proc over the enumerable" do
          expect(subject.call).to eq(expected)
        end
      end
    end

  end

end
