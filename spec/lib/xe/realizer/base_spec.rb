require 'spec_helper'

describe Xe::Realizer::Base do

  subject { klass.new }

  let(:klass)   { Class.new(Xe::Realizer::Base) }

  describe '.[]' do

    before do
      # We don't want to test the relationship between the class method and
      # the instance method, not the implementation of the latter.
      klass.any_instance.stub(:[]) { {} }
      # Construct the default realizer instance.
      klass[0]
      @realizer = klass.instance_variable_get(:@default)
    end

    it "constructs a default realizer instance" do
      expect(@realizer).to be_an_instance_of(klass)
    end

    it "calls #[] on an instance of Xe::Realizer::Base" do
      expect(@realizer).to receive(:[]).with(2)
      klass[2]
    end

  end

  describe '#[]' do

    let(:id)        { 1 }
    let(:key)       { 2 }
    let(:proxy_id)  { 3 }
    let(:group_key) { 4 }
    let(:results)   { {} }
    let(:enabled)   { true }

    let(:context) do
      double(Xe::Context).tap do |context|
        context.stub(:enabled?) { enabled }
        context.stub(:defer)
      end
    end

    before do
      # We don't want to test the actual relationship between the realizer base
      # class and the context, only the interface.
      Xe::Context.stub(:current) { context }
      # Additionally, we don' want to resolve a proxy in our tests. Only verify
      # that Proxy.resolve is called and that the returned value is used.
      Xe::Proxy.stub(:resolve) { proxy_id }

      subject.stub(:perform) { results }
      subject.stub(:group_key) { group_key }
    end

    it "calls Proxy.resolve with the id" do
      expect(Xe::Proxy).to receive(:resolve).with(1)
      subject[1]
    end

    context "when the context is enabled" do
      let(:enabled) { true }

      it "calls defer on the current context" do
        expect(context).to receive(:defer).with(subject, proxy_id, group_key)
        subject[1]
      end
    end

    context "when the context is disabled" do
      let(:enabled) { false }
      let(:results) { { proxy_id => 10 } }

      it "invokes the #call/#perform methods directly" do
        expect(subject[1]).to eq(10)
      end
    end

    context "when no current context exists" do
      let(:context) { nil }
      let(:results)  { { proxy_id => 12 } }

      it "invokes the #call/#perform methods directly" do
        expect(subject[1]).to eq(12)
      end
    end

    it "delegates to #group_key to compute the key" do
      subject.stub(:group_key).and_return('abc')
      expect(context).to receive(:defer).with(anything, anything, 'abc')
      subject[1]
    end

  end

  describe '#perform' do

    let(:group) { [1, 2, 3] }
    let(:key)   { 1 }

    it "raises NotImplementedError" do
      expect { subject.perform(group, key) }.to raise_error(NotImplementedError)
    end

  end

  describe '#group_key' do

    it "is nil" do
      expect(subject.group_key(0)).to be_nil
    end

  end

  describe '#new_group' do

    it "returns an instance of Set" do
      expect(subject.new_group(0)).to be_an_instance_of(Set)
    end

    it "returns distinct sets" do
      group1 = subject.new_group(0)
      group2 = subject.new_group(0)
      expect(group1.object_id).to_not eq(group2.object_id)
    end

  end

  describe '#group_as_array' do

    it "is true" do
      expect(subject.group_as_array?).to be_true
    end

  end

  describe '#transform' do

    let(:group)   { [1, 2, 3] }
    let(:results) { {} }

    context "when results is a Hash" do
      let(:results) { {1 => 4, 2 => 5, 3 => 6} }

      it "returns the results unchanged" do
        expect(subject.transform(group, results)).to eq(results)
      end
    end

    context "when results is an Array" do
      let(:results)  { [7, 8, 9] }
      let(:expected) { {1 => 7, 2 => 8, 3 => 9} }

      it "zips the group with the results and returns the pairs as a hash" do
        expect(subject.transform(group, results)).to eq(expected)
      end
    end

  end

  describe '#call' do

    let(:ids)   { [1, 2, 3] }
    let(:group) { Array.new(ids) }
    let(:key)   { 2 }

    def invoke
      subject.call(group, key)
    end

    it "invokes #perform with the ids" do
      captured_ids = nil
      subject.stub(:perform) { |group| captured_ids = group }
      invoke
      expect(captured_ids).to match_array(ids)
    end

    context "when as_array is true" do

      before do
        subject.stub(:group_as_array?).and_return(true)
      end

      context "when the group is not an array" do
        let(:group) { Set.new(ids) }

        it "invokes #perform with the ids" do
          captured_ids = nil
          subject.stub(:perform) { |group| captured_ids = group }
          invoke
          expect(captured_ids).to match_array(ids)
        end

        it "invoke #perform after coercing the group to an array" do
          captured_ids = nil
          subject.stub(:perform) { |group| captured_ids = group }
          invoke
          expect(captured_ids).to be_an_instance_of(Array)
        end
      end
    end

    context "when perform/transform something other than a Hash" do
      let(:object) { double("An Object") }

      before do
        subject.stub(:perform) { object }
      end

      it "raises UnsupportedRealizationTypeError" do
        expect { invoke }.to raise_error(Xe::UnsupportedRealizationTypeError)
      end
    end

  end

  describe '#inspect' do

    it "is a string" do
      expect(subject.inspect).to be_an_instance_of(String)
    end

  end

  describe '#to_s' do

    it "is a string" do
      expect(subject.to_s).to be_an_instance_of(String)
    end

  end

end
