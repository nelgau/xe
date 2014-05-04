require 'spec_helper'

describe Xe::Realizer::Id do
  include Xe::Test::Mock::Realizer::Id

  subject { klass.new(&id_proc) }

  let(:klass)   { Class.new(Xe::Realizer::Id) }
  let(:value)   { new_value_mock(10) }
  let(:id_proc) { nil }

  describe '.id' do

    it "converts a method symbol to a proc that calls it" do
      id_proc = klass.id(:id2)
      expect(id_proc.call(value)).to eq(11)
    end

    it "accepts an proc that operates on a value" do
      id_proc = klass.id { |v| v.id }
      expect(id_proc.call(value)).to eq(10)
    end

    it "returns the last value set on it" do
      klass.id(:id2)
      id_proc = klass.id
      expect(id_proc.call(value)).to eq(11)
    end

  end

  describe '.default_id_proc' do

    it "converts a value to an id (using Value#id)" do
      expect(klass.default_id_proc.call(value)).to eq(10)
    end

  end

  describe '#initialize' do

    context "when no id_proc is given and no id_proc is set on the class" do
      it "sets the id_proc attribute as the default" do
        expect(subject.id_proc).to eq(klass.default_id_proc)
      end
    end

    context "when no id_proc is given but one is set on the class" do
      before do
        klass.id(:id2)
      end

      it "sets the id_proc attribute with the one on the class" do
        expect(subject.id_proc).to eq(klass.id)
      end
    end

    context "when an id_proc is given directly to the initializer" do
      let(:id_proc) { Proc.new { |v| v.id2 } }

      it "sets the id_proc attribute with the block" do
        expect(subject.id_proc).to eq(id_proc)
      end
    end

  end

  describe '#perform' do

    it "raises NotImplementedError" do
      expect { subject.perform([1, 2, 3]) }.to raise_error(NotImplementedError)
    end

  end

  describe '#call' do

    let(:group)   { [10, 22, 23] }
    let(:results) { group.map { |id| new_value_mock(id) } }
    let(:id_proc) { Proc.new { |v| v.id2 } }

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

      subject.call(group)
      expect(captured_group).to eq(group)
    end

    it "returns a map from ids to results" do
      expect(subject.call(group)).to eq(expected)
    end

  end

end