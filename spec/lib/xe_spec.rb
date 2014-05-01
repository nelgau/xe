require 'spec_helper'

describe Xe do
  subject { Xe }

  let(:proc) do
    Proc.new do |ids|
      ids.each_with_object({}) { |i, h| h[i] = i * 2 }
    end
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
      expect(subject.realizer(&proc)).to be_an_instance_of(Xe::Realizer::Proc)
    end

    it "returns a realizer which immediate yields values" do
      realizer = subject.realizer(&proc)
      expect(realizer[2]).to eq(4)
    end

  end

  describe '.map' do

    it "maps" do
      result = subject.map([1, 2, 3]) { |i| i * 3 }
      expect(result).to eq([3, 6, 9])
    end

    it "maps using deferred values" do
      realizer = subject.realizer(&proc)
      result = subject.map([1, 2, 3]) { |i| realizer[i] }
      expect(result).to eq([2, 4, 6])
    end

  end

end
