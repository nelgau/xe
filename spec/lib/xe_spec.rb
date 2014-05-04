require 'spec_helper'

describe Xe do

  subject { Xe }

  let(:mapping_proc) do
    Proc.new do |x|
      x * 2
    end
  end

  let(:realizer_proc) do
    Proc.new do |ids|
      ids.each_with_object({}) do |i, h|
        h[i] = mapping_proc.call(i)
      end
    end
  end

  def invoke_realizer
    subject.realizer(&realizer_proc)
  end

  describe '.context' do

    it "yields a context" do
      captured_context = nil
      subject.context { |c| captured_context = c }
      expect(captured_context).to be_an_instance_of(Xe::Context)
    end

    it "returns the result of the block" do
      expect(subject.context { 2 }).to eq(2)
    end

  end

  describe '.realizer' do

    it "returns a Xe::Realizer::Proc" do
      expect(invoke_realizer).to be_an_instance_of(Xe::Realizer::Proc)
    end

    it "returns a realizer which immediate yields values" do
      expect(invoke_realizer[2]).to eq(4)
    end

  end

  describe '.map' do

    let(:ids)      { [1, 2, 3, 4] }
    let(:output)   { [2, 4, 6, 8] }
    let(:realizer) { invoke_realizer }

    it "maps over an enumeable" do
      result = subject.map(ids, &mapping_proc)
      expect(result).to eq(output)
    end

    it "maps using deferred values" do
      result = subject.map(ids) { |i| realizer[i] }
      expect(result).to eq(output)
    end

    context "while wrapped in a context" do
      let(:output) { [4, 8, 12, 16] }

      it "maps deferred values to deferred values" do
        result1 = subject.map(ids) { |i| realizer[i] }
        result2 = subject.map(result1) { |i| realizer[i] }
        expect(result2).to eq(output)
      end
    end

  end

end
