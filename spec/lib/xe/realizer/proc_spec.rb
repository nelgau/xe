require 'spec_helper'

describe Xe::Realizer::Proc do

  subject { Xe::Realizer::Proc.new(tag, &realize_proc) }

  let(:tag)          { :foo }
  let(:realize_proc) { Proc.new { results } }
  let(:results)      { { 1 => 2 } }

  describe '#initialize' do

    it "sets the tag attribute" do
      expect(subject.tag).to eq(tag)
    end

    it "sets the realize_proc attribute" do
      expect(subject.realize_proc).to eq(realize_proc)
    end

    context "when no block is given" do
      let(:realize_proc) { nil }

      it "raises ArgumentError" do
        expect { subject }.to raise_error(ArgumentError)
      end

    end

  end

  describe '#perform' do

    let(:group) { [1, 2, 3] }
    let(:key)   { 0 }

    it "calls #call_proc with the group" do
      expect(realize_proc).to receive(:call).with(group, key)
      subject.perform(group, key)
    end

    it "returns the result of calling #realize_proc" do
      expect(subject.perform(group, key)).to eq(results)
    end

  end

end
