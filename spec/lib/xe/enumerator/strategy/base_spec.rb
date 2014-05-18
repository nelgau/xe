require 'spec_helper'

describe Xe::Enumerator::Strategy::Base do
  include Xe::Test::Helper::Enumerator
  include Xe::Test::Mock::Enumerator

  subject do
    Xe::Enumerator::Strategy::Base.new(context, options)
  end

  let(:options) { {} }

  describe '.call' do

    let(:klass)    { Xe::Enumerator::Strategy::Base }
    let(:instance) { klass.new(context) }

    before do
      instance.stub(:call)
    end

    it "creates an instance of the strategy" do
      expect(klass).to receive(:new).with(context, 1, 2, 3) { instance }
      klass.call(context, 1, 2, 3)
    end

    it "invokes call on the instance" do
      klass.stub(:new).and_return(instance)
      expect(instance).to receive(:call)
      klass.call(context)
    end
  end

  describe '#initialize' do

    it "sets the context attribute" do
      expect(subject.context).to eq(context)
    end

    it "sets the concurrent attribute to true" do
      expect(subject).to be_concurrent
    end

    context "when the concurrent option is given to be false" do
      before do
        options.merge!(:concurrent => false)
      end

      it "sets the concurrent attribute to false" do
        expect(subject).to_not be_concurrent
      end
    end

  end

  describe '#call' do

    before do
      # Stub these so that we don't raise NotImplementedErrors.
      subject.stub(:perform)
      subject.stub(:perform_serial)
    end

    shared_examples_for "a concurrent execution" do
      it "invokes #perform" do
        expect(subject).to receive(:perform)
        subject.call
      end

      it "returns the result of #perform" do
        subject.stub(:perform).and_return('foo')
        expect(subject.call).to eq('foo')
      end
    end

    shared_examples_for "a serial execution" do
      it "invokes #perform_serial" do
        expect(subject).to receive(:perform_serial)
        subject.call
      end

      it "returns the result of #perform" do
        subject.stub(:perform_serial).and_return('bar')
        expect(subject.call).to eq('bar')
      end
    end

    context "when the context is enabled" do
      let(:enabled) { true }
      it_behaves_like "a concurrent execution"
    end

    context "when the context is disabled" do
      let(:enabled) { false }
      it_behaves_like "a serial execution"
    end

    context "when the concurrent option is given to be false" do
      before { options.merge!(:concurrent => false) }
      it_behaves_like "a concurrent execution"
    end

  end

  describe '#perform' do

    it "raises NotImplementedError" do
      expect { subject.perform }.to raise_error(NotImplementedError)
    end

  end

  describe '#perform_serial' do

    it "raises NotImplementedError" do
      expect { subject.perform_serial }.to raise_error(NotImplementedError)
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
