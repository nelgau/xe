require 'spec_helper'

describe Xe::Enumerator::Strategy::Base do
  include Xe::Test::Mock::Enumerator::Strategy

  subject { Xe::Enumerator::Strategy::Base.new(context) }

  let(:context) { new_context_mock }

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

    it "sets the context" do
      expect(subject.context).to eq(context)
    end

  end

  describe '#call' do

    it "raises NotImplementedError" do
      expect { subject.call }.to raise_error(NotImplementedError)
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
