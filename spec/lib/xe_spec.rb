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

  describe '.each' do

    let(:ids)      { [1, 2, 3, 4] }
    let(:realizer) { invoke_realizer }

    it "returns the enumerated collection" do
      result = subject.each(ids) { |i| i + 1 }
      expect(result).to eq(ids)
    end

    it "invokes the block for each" do
      sum = 0
      subject.each(ids) { |i| sum += i }
      expect(sum).to eq(10)
    end

    it "invokes the block for each while deferring values" do
      sum = 0
      subject.each(ids) { |i| r = realizer[i].to_i; sum += r }
      expect(sum).to eq(20)
    end

  end

  describe '.map' do

    let(:ids)      { [1, 2, 3, 4] }
    let(:output)   { [2, 4, 6, 8] }
    let(:realizer) { invoke_realizer }

    it "maps over an enumerable" do
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

  describe '.enum' do

    let(:ids)    { [1, 2, 3] }

    context "when a context exists" do
      around do |example|
        Xe.context { example.run }
      end

      it "returns an instance of Xe:Enumerator" do
        expect(Xe.enum(ids)).to be_an_instance_of(Xe::Enumerator)
      end

      it "enumerates" do
        expect(Xe.enum(ids).first).to eq(1)
      end
    end

    context "when there is no context" do
      it "raises Xe::NoContextError" do
        expect { Xe.enum(ids) }.to raise_error(Xe::NoContextError)
      end
    end

  end

  describe '.configure' do

    it "yields an instance of the configuration object" do
      captured_config = nil
      Xe.configure { |c| captured_config = c }
      expect(captured_config).to be_an_instance_of(Xe::Configuration)
    end

  end

end
