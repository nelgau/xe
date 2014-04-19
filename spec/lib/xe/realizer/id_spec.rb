require 'spec_helper'

describe Xe::Realizer::Id do
  include Xe::Test::Mock::Realizer::Id

  subject { klass.new(&value_id) }

  let(:klass)    { Class.new(Xe::Realizer::Id) }
  let(:value)    { new_value_mock(10) }
  let(:value_id) { nil }

  describe '.id' do

    it "converts a method symbol to a proc that calls it" do
      value_id = klass.value_id(:id2)
      expect(value_id.call(value)).to eq(11)
    end

    it "accepts an proc that operates on a value" do
      value_id = klass.value_id { |v| v.id }
      expect(value_id.call(value)).to eq(10)
    end

    it "returns the last value set on it" do
      klass.value_id(:id2)
      value_id = klass.value_id
      expect(value_id.call(value)).to eq(11)
    end

  end

  describe '.default_value_id' do

    it "converts a value to an id (using Value#id)" do
      expect(klass.default_value_id.call(value)).to eq(10)
    end

  end

  describe '#initialize' do

    context "when no value_id is given and no value_id is set on the class" do
      it "sets the value_id attribute as the default" do
        expect(subject.value_id).to eq(klass.default_value_id)
      end
    end

    context "when no value_id is given but one is set on the class" do
      before do
        klass.value_id(:id2)
      end

      it "sets the value_id attribute with the one on the class" do
        expect(subject.value_id).to eq(klass.value_id)
      end
    end

    context "when an value_id is given directly to the initializer" do
      let(:value_id) { Proc.new { |v| v.id2 } }

      it "sets the value_id attribute with the block" do
        expect(subject.value_id).to eq(value_id)
      end
    end

  end

  describe '#perform' do

    let(:group) { [1, 2, 3] }
    let(:key)   { 2 }

    it "raises NotImplementedError" do
      expect { subject.perform(group, key) }.to raise_error(NotImplementedError)
    end

  end

  describe '#call' do

    let(:group)    { [10, 22, 23] }
    let(:key)      { 2 }

    let(:results)  { group.map { |id| new_value_mock(id) } }
    let(:value_id) { Proc.new { |v| v.id2 } }

    let(:expected) do
      results.each_with_object({}) do |v, rs|
        rs[v.id2] = v
      end
    end

    before do
      # Stub the realizer to return a result set.
      subject.stub(:perform) { results }
    end

    it "invokes #perform with the group" do
      captured_group = nil
      subject.stub(:perform) do |group|
        captured_group = group
        results
      end

      subject.call(group, key)
      expect(captured_group).to eq(group)
    end

    it "returns a map from ids to results" do
      expect(subject.call(group, key)).to eq(expected)
    end

  end

end