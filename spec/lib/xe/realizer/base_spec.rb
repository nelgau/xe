require 'spec_helper'

describe Xe::Realizer::Base do

  let(:klass) { Class.new(Xe::Realizer::Base) }
  subject     { klass.new }

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
      @realizer.should_receive(:[]).with(1)
      klass[1]
    end

  end

  describe '#[]' do

    let(:id)        { 1 }
    let(:proxy_id)  { 2 }
    let(:group_key) { 3 }
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
      Xe::Proxy.should_receive(:resolve).with(1)
      subject[1]
    end

    context "when the context is not disabled" do
      let(:disabled) { false }

      it "calls defer on the current context" do
        context.should_receive(:defer).with(subject, proxy_id, group_key)
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

  end

  describe '#call' do

    it "raises NotImplementedError" do
      expect { subject.call([]) }.to raise_error(NotImplementedError)
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
