require 'spec_helper'

describe Xe::Enumerator::Strategy::Mapper do
  include Xe::Test::Helper::Enumerator
  include Xe::Test::Mock::Enumerator

  subject do
    Xe::Enumerator::Strategy::Mapper.new(context, enumerable, &map_proc)
  end

  let(:map_proc)    { double_proc }

  let(:double_proc) { Proc.new { |i| i * 2 } }
  let(:expected)    { enumerable.map(&double_proc) }

  let(:all_wait_proc) do
    Proc.new do |index|
      value = wait_for_index(index)
      double_proc.call(value)
    end
  end

  describe '#initialize' do

    it "delegates to super to set the context" do
      expect(subject.context).to eq(context)
    end

    it "sets the enum attribute" do
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

    context "when the context is enabled" do
      let(:enabled) { true }

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
          release_enumerable_waiters
          results.each_with_index do |result, index|
            expect(result.subject).to eq(expected[index])
          end
        end
      end
    end

    context "when the context is disabled" do
      let(:enabled) { false }

      before do
        expect_serial!
      end

      context "when map_proc doesn't wait" do
        let(:inject_proc) { sum_proc }

        it "returns the mapping of map_proc over the enumerable" do
          expect(subject.call).to eq(expected)
        end
      end
    end

  end

end
