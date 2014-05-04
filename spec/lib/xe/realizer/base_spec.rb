require 'spec_helper'

describe Xe::Realizer::Base do

  subject { klass.new(options) }

  let(:klass)   { Class.new(Xe::Realizer::Base) }
  let(:options) { {} }

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
      expect(@realizer).to receive(:[]).with(1, 2)
      klass[1, 2]
    end

    it "accepts a single argument" do
      expect(@realizer).to receive(:[]).with(1, nil)
      klass[1]
    end

  end

  describe '#[]' do

    let(:id)        { 1 }
    let(:key)       { 2 }
    let(:proxy_id)  { 3 }
    let(:group_key) { 4 }
    let(:results)   { {} }
    let(:disabled)  { false }

    let(:context) do
      double(Xe::Context).tap do |context|
        context.stub(:disabled?) { disabled }
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

    context "when the context is not disabled" do
      let(:disabled) { false }

      it "calls defer on the current context" do
        expect(context).to receive(:defer).with(subject, proxy_id, group_key)
        subject[1]
      end
    end

    context "when the context is disabled" do
      let(:disabled) { true }
      let(:results)  { { proxy_id => 10 } }

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

    context "when a key is provided" do
      let(:key) { 2 }

      it "defers using that key" do
        expect(context).to receive(:defer).with(anything, anything, key)
        subject[1, key]
      end
    end

    context "when a key is not provided" do
      let(:key) { nil }

      it "delegates to #group_key to compute the key" do
        subject.stub(:group_key).and_return('abc')
        expect(context).to receive(:defer).with(anything, anything, 'abc')
        subject[1, key]
      end
    end

  end

  describe '#perform' do

    let(:group) { [1, 2, 3] }

    it "raises NotImplementedError" do
      expect { subject.perform(group) }.to raise_error(NotImplementedError)
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

  describe '#initialize' do

    it "sets the group_as_array attribute to its default true value" do
      expect(subject.group_as_array?).to be_true
    end

    context "when the :group_as_array => false option is passed" do
      before do
        options.merge!(:group_as_array => false)
      end

      it "sets the group_as_array attribute to false" do
        expect(subject.group_as_array?).to be_false
      end
    end

  end

  describe '#group_as_array' do

    it "defaults to true" do
      expect(subject.group_as_array?).to be_true
    end

    context "when the @group_as_array instance variable is nil" do
      before do
        options.merge!(:group_as_array => nil)
      end

      it "is true" do
        expect(subject.instance_variable_get(:@group_as_array)).to be_nil
        expect(subject.group_as_array?).to be_true
      end
    end

  end

  describe '#call' do

    let(:ids)   { [1, 2, 3] }
    let(:group) { Array.new(ids) }

    it "invokes #perform with the ids" do
      captured_ids = nil
      subject.stub(:perform) { |group| captured_ids = group }
      subject.call(group)
      expect(captured_ids).to match_array(ids)
    end

    context "when as_array is true" do
      before do
        options.merge!(:group_as_array => true)
      end

      context "when the group is not an array" do
        let(:group) { Set.new(ids) }

        it "invokes #perform with the ids" do
          captured_ids = nil
          subject.stub(:perform) { |group| captured_ids = group }
          subject.call(group)
          expect(captured_ids).to match_array(ids)
        end

        it "invoke #perform after coercing the group to an array" do
          captured_ids = nil
          subject.stub(:perform) { |group| captured_ids = group }
          subject.call(group)
          expect(captured_ids).to be_an_instance_of(Array)
        end
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
      expect(subject.inspect).to be_an_instance_of(String)
    end

  end

end
